import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nanday_twitch_app/models/db_stream.dart';
import 'package:nanday_twitch_app/models/stream_online_info.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/services/session_repository.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';

abstract class TwitchStreamPoller {
  ///
  /// Starts the Twitch "Streams" API polling to check if channel is online or not
  ///
  void startPollingTwitchStreams();
}

class TwitchStreamPollerImpl implements TwitchStreamPoller {
  TwitchStreamPollerImpl(this._sessionRepository, this._authenticationService, this._eventService, this._storageService, this._loggerService);

  final SessionRepository _sessionRepository;
  final TwitchAuthenticationService _authenticationService;
  final EventService _eventService;
  final PersistentStorageService _storageService;
  final LoggerService _loggerService;

  bool _lastOnlineStatus = false;
  String? _lastStreamTwitchId = null;

  @override
  void startPollingTwitchStreams() async {
    Map<String, String> headers = _authenticationService.generateApiHeaders();
    Uri streamsEndpoint = Uri.parse('https://api.twitch.tv/helix/streams?user_id=${_sessionRepository.userId}');
    while (true) {
      try {
        http.Response response = await http.get(streamsEndpoint, headers: headers);
        dynamic responseJson = jsonDecode(response.body);
        bool channelOnline = (responseJson['data'] as List).isNotEmpty;
        String? title;
        DateTime? streamLiveSince;
        if (channelOnline) {
          dynamic data = responseJson['data'][0];
          title = data['title'];
          streamLiveSince = DateTime.parse(data['started_at']);
          _lastStreamTwitchId = data['id'];
        }
        _setLastOnlineStatus(channelOnline, title, streamLiveSince);
      } catch (e) {
        _loggerService.w(e.toString());
      }
      await Future.delayed(const Duration(minutes: 1));
    }
  }

  void _setLastOnlineStatus(bool value, String? streamTitle, DateTime? streamLiveSince) async {
    if (value != _lastOnlineStatus) {
      _lastOnlineStatus = value;
      late DbStream dbStream;
      if (_lastStreamTwitchId == null) {
        return;
      }
      String twitchStreamId = _lastStreamTwitchId!;
      if (_lastStreamTwitchId != null) {
        var streamFromDb = await _storageService.getDbStreamByTwitchId(twitchStreamId);
        if (streamFromDb == null) {
          dbStream = DbStream(
              twitchStreamId,
              streamTitle ?? "",
              streamLiveSince?.millisecondsSinceEpoch ?? 0,
              value == false ? DateTime
                  .now()
                  .millisecondsSinceEpoch : null
          );
        } else {
          dbStream = value == false ? streamFromDb.copyWithEndTimestampUtc(DateTime.now()) : streamFromDb;
        }
      }
      _sessionRepository.streamLiveSince = streamLiveSince;
      await _eventService.streamOnlineChanged(StreamOnlineInfo(value, streamTitle, dbStream));
      if (value && false == dbStream.countsReset) {
        await _storageService.resetAllCounts();
        dbStream.countsReset = true;
      }
      await _storageService.createOrUpdateDbStream(dbStream);
    }
  }
}
