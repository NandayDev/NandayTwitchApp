import 'dart:collection';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nanday_twitch_app/models/twitch_notification.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';

abstract class TwitchFollowerPoller {
  void initialize();
}

class TwitchFollowerPollerImpl implements TwitchFollowerPoller {
  TwitchFollowerPollerImpl(this._twitchKeysReader, this._storageService, this._authenticationService, this._loggerService, this._eventService);

  final TwitchKeysReader _twitchKeysReader;
  final PersistentStorageService _storageService;
  final TwitchAuthenticationService _authenticationService;
  final LoggerService _loggerService;
  final EventService _eventService;
  final HashMap<String, String> _currentFollowers = HashMap();

  @override
  void initialize() async {
    Duration pollIntervalDuration = const Duration(seconds: 5);
    TwitchKeys keys = await _twitchKeysReader.getTwitchKeys();
    Map<String, String> headers = {'Authorization': 'Bearer ${_authenticationService.accessToken!}', 'Client-Id': keys.applicationClientId};

    int? userId = await _getUserId(_storageService.currentProfile!.channelName, headers);
    if (userId == null) {
      return;
    }

    Uri getUsersFollowsEndpoint = Uri.parse('https://api.twitch.tv/helix/users/follows?to_id=$userId');

    await _pollUsersFollowsEndpoint(getUsersFollowsEndpoint, headers, false);
    while (true) {
      await Future.delayed(pollIntervalDuration);
      _pollUsersFollowsEndpoint(getUsersFollowsEndpoint, headers, true);
    }
  }

  Future<int?> _getUserId(String userLogin, Map<String, String> headers) async {
    int retries = 0;
    while (retries < 3) {
      try {
        http.Response response = await http.get(Uri.parse('https://api.twitch.tv/helix/users?$userLogin'), headers: headers);
        dynamic responseJson = jsonDecode(response.body);
        for (dynamic data in responseJson['data']) {
          _loggerService.d('Correctly fetched user id');
          return int.parse(data['id']);
        }
        retries++;
        await Future.delayed(const Duration(seconds: 5));
      } catch (e) {
        _loggerService.w('Could not get user id: ${e.toString()} retrying.');
      }
    }
    _loggerService.e('Could not get user id: aborting');
    return null;
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
