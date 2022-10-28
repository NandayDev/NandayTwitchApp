import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/session_repository.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';

abstract class TwitchStreamPoller {
  ///
  /// Starts the Twitch "Streams" API polling to check if channel is online or not
  ///
  void startPollingTwitchStreams();
}

class TwitchStreamPollerImpl implements TwitchStreamPoller {
  TwitchStreamPollerImpl(this._sessionRepository, this._authenticationService, this._eventService, this._loggerService);

  final SessionRepository _sessionRepository;
  final TwitchAuthenticationService _authenticationService;
  final EventService _eventService;
  final LoggerService _loggerService;

  bool __lastOnlineStatus = false;

  set _lastOnlineStatus(bool value) {
    if (value != __lastOnlineStatus) {
      __lastOnlineStatus = value;
      _eventService.channelOnlineChanged(value);
    }
  }

  @override
  void startPollingTwitchStreams() async {
    Map<String, String> headers = _authenticationService.generateApiHeaders();
    Uri streamsEndpoint = Uri.parse('https://api.twitch.tv/helix/streams?user_id=${_sessionRepository.userId}');
    while (true) {
      try {
        http.Response response = await http.get(streamsEndpoint, headers: headers);
        dynamic responseJson = jsonDecode(response.body);
        _lastOnlineStatus = (responseJson['data'] as List).isNotEmpty;
        await Future.delayed(const Duration(minutes: 1));
      } catch (e) {
        _loggerService.w(e.toString());
      }
    }
  }
}
