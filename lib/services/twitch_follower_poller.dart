import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nanday_twitch_app/models/twitch_notification.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';

abstract class TwitchFollowerPoller {
  Future initialize();
}

class TwitchFollowerPollerImpl implements TwitchFollowerPoller {
  TwitchFollowerPollerImpl(this._twitchKeysReader, this._authenticationService, this._loggerService, this._eventService);

  final TwitchKeysReader _twitchKeysReader;
  final TwitchAuthenticationService _authenticationService;
  final LoggerService _loggerService;
  final EventService _eventService;
  final HashMap<String, String> _currentFollowers = HashMap();

  @override
  Future initialize() async {
    TwitchKeys keys = await _twitchKeysReader.getTwitchKeys();
    Map<String, String> headers = {'Authorization': 'Bearer ${_authenticationService.accessToken!}', 'Client-Id': keys.applicationClientId};

    Uri getUsersFollowsEndpoint = Uri.parse('https://api.twitch.tv/helix/users/follows?to_id=${_authenticationService.userId!}');

    await _pollUsersFollowsEndpoint(getUsersFollowsEndpoint, headers, false);
    _startContinuousUsersPolling(getUsersFollowsEndpoint, headers);
  }

  void _startContinuousUsersPolling(Uri getUsersFollowsEndpoint, Map<String, String> headers) async {
    Duration pollIntervalDuration = const Duration(seconds: 5);
    while (true) {
      await Future.delayed(pollIntervalDuration);
      _pollUsersFollowsEndpoint(getUsersFollowsEndpoint, headers, true);
    }
  }

  Future _pollUsersFollowsEndpoint(Uri getUsersFollowsEndpoint, Map<String, String> headers, bool notifyNewFollower) async {
    try {
      http.Response response = await http.get(getUsersFollowsEndpoint, headers: headers);
      dynamic responseJson = jsonDecode(response.body);
      for (dynamic data in responseJson['data']) {
        String followerLogin = data['from_login'];
        String followerDisplayName = data['from_name'];
        if (!_currentFollowers.containsKey(followerLogin)) {
          _currentFollowers[followerLogin] = followerDisplayName;
          if (notifyNewFollower) {
            TwitchNotification notification = TwitchNotification(TwitchNotificationType.NEW_FOLLOWER, followerDisplayName);
            _eventService.notificationReceived(notification);
          }
        }
      }
    } catch (e) {
      _loggerService.w(e.toString());
    }
  }
}
