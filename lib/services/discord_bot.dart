import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';
import 'package:nyxx/nyxx.dart';

abstract class DiscordBot {
  Future initialize();

  Future sendAnnouncement(String text);
}

class NyxxDiscordBot implements DiscordBot {

  NyxxDiscordBot(this._keysReader, this._loggerService);

  final TwitchKeysReader _keysReader;
  final LoggerService _loggerService;

  late final INyxxWebsocket _nyxxWebSocket;

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
  }

  @override
  Future sendAnnouncement(String text) async {
    var channel = await _nyxxWebSocket.fetchChannel<ITextChannel>(Snowflake(1035430141725261844));
    channel.sendMessage(MessageBuilder.content(text));
  }
}