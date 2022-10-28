import 'dart:convert';

import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';
import 'package:http/http.dart' as http;

abstract class TwitchStreamPoller {
  void startPollingTwitchStreams();
}

class TwitchStreamPollerImpl implements TwitchStreamPoller {

  TwitchStreamPollerImpl(this._twitchKeysReader, this._authenticationService, this._eventService, this._loggerService);

  final TwitchKeysReader _twitchKeysReader;
  final TwitchAuthenticationService _authenticationService;
  final EventService _eventService;
  final LoggerService _loggerService;

  @override
  void startPollingTwitchStreams() async {
    Map<String,String> headers = _authenticationService.generateApiHeaders();
    Uri streamsEndpoint = Uri.parse('https://api.twitch.tv/helix/streams?user_id=${_authenticationService.userId!}');
    while (true) {
      try {
        http.Response response = await http.get(streamsEndpoint, headers: headers);
        dynamic responseJson = jsonDecode(response.body);
        for (dynamic data in responseJson['data']) {

          String a = data['user_id'];

        }
        await Future.delayed(const Duration(minutes: 1));
      } catch (e) {
        _loggerService.w(e.toString());
      }
    }
  }

}