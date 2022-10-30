import 'package:intl/intl.dart';
import 'package:nanday_twitch_app/models/twich_api_responses.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/localizer.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/session_repository.dart';
import 'package:nanday_twitch_app/services/twitch_api_service.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';
import 'package:nyxx/nyxx.dart';

abstract class DiscordBot {
  Future initialize();

  Future sendAnnouncement(String text);
}

class NyxxDiscordBot implements DiscordBot {
  NyxxDiscordBot(this._keysReader, this._eventService, this._localizer, this._sessionRepository, this._twitchApiService, this._loggerService);

  final TwitchKeysReader _keysReader;
  final EventService _eventService;
  final Localizer _localizer;
  final SessionRepository _sessionRepository;
  final TwitchApiService _twitchApiService;
  final LoggerService _loggerService;

  late final INyxxWebsocket _nyxxWebSocket;
  late final Iterable<int> _channelIds;

  @override
  Future initialize() async {
    TwitchKeys keys = await _keysReader.getTwitchKeys();
    _nyxxWebSocket = NyxxFactory.createNyxxWebsocket(keys.discordBotToken, 2048)
      ..registerPlugin(Logging()) // Default logging plugin
      ..registerPlugin(CliIntegration()) // Cli integration for nyxx allows stopping application via SIGTERM and SIGKILl
      ..registerPlugin(IgnoreExceptions());

    await _nyxxWebSocket.connect();

    _nyxxWebSocket.eventsWs.onReady.listen((event) {
      _loggerService.i("Discord bot is ready");
    });

    _nyxxWebSocket.eventsWs.onMessageReceived.listen((e) {
      // Check if message content equals "!ping"
      if (e.message.content == "!ping") {
        // Send "Pong!" to channel where message was received
        e.message.channel.sendMessage(MessageBuilder.content("Pong!"));
      }
    });

    _eventService.subscribeToChannelOnlineChangedEvent((info) async {
      if (info.isStarted) {
        // Twitch channel went online //
        sendAnnouncement(Localizer.getStringWithPlaceholders(_localizer.localizations.channelOnlineDiscordMessage + " - " + (info.streamTitle ?? ""),
            [_sessionRepository.userDisplayName, 'https://www.twitch.tv/${_sessionRepository.username}']));
      } else {
        // Twitch channel went offline //
        var streamScheduleResult = await _twitchApiService.getStreamSchedule();
        if (streamScheduleResult.isSuccessful) {
          StreamSchedule streamSchedule = streamScheduleResult.result!;
          if (streamSchedule.elements.isNotEmpty) {
            StreamScheduleElement nextStreamElement = streamSchedule.elements[0];
            sendAnnouncement(Localizer.getStringWithPlaceholders(_localizer.localizations.channelOfflineDiscordMessageWithNextStream,
                [_sessionRepository.userDisplayName, DateFormat.yMMMMEEEEd().format(nextStreamElement.startTime)]));
          }
        }
      }
    });

    _channelIds = keys.discordChannelIds;
  }

  @override
  Future sendAnnouncement(String text) async {
    for (int channelId in _channelIds) {
      var channel = await _nyxxWebSocket.fetchChannel<ITextChannel>(Snowflake(channelId));
      channel.sendMessage(MessageBuilder.content(text));
    }
  }
}
