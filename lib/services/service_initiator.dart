import 'package:nanday_twitch_app/services/broadcast_messages_service.dart';
import 'package:nanday_twitch_app/services/discord_bot.dart';
import 'package:nanday_twitch_app/services/localizer.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/nanday_dependency_injector.dart';
import 'package:nanday_twitch_app/services/sound_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_command_service.dart';
import 'package:nanday_twitch_app/services/twitch_follower_poller.dart';
import 'package:nanday_twitch_app/services/twitch_thanker.dart';

///
/// A class to initialize important services
class ServiceInitiator {
  ServiceInitiator(this._botLocalizer, this._twitchChatCommandService, this._twitchThanker, this._twitchFollowerPoller, this._soundService,
      this._broadcastMessagesService, this._loggerService, this._discordBot);

  final Localizer _botLocalizer;
  final TwitchChatCommandService _twitchChatCommandService;
  final TwitchThanker _twitchThanker;
  final TwitchFollowerPoller _twitchFollowerPoller;
  final SoundService _soundService;
  final BroadcastMessagesService _broadcastMessagesService;
  final LoggerService _loggerService;
  final DiscordBot _discordBot;

  Future initializeAtAppStartup() {
    return Future.wait([_loggerService.initialize()]);
  }

  Future initializeWhenLoggedIn() {
    return Future.wait([
      _botLocalizer.initialize(),
      _twitchChatCommandService.initialize(),
      _soundService.initialize(),
      _twitchThanker.initialize(),
      _twitchFollowerPoller.initialize(),
      _broadcastMessagesService.initialize(),
      _discordBot.initialize()
    ]);
  }

  static ServiceInitiator instance = ServiceInitiator(
      NandayDependencyInjector.instance.resolve(),
      NandayDependencyInjector.instance.resolve(),
      NandayDependencyInjector.instance.resolve(),
      NandayDependencyInjector.instance.resolve(),
      NandayDependencyInjector.instance.resolve(),
      NandayDependencyInjector.instance.resolve(),
      NandayDependencyInjector.instance.resolve(),
      NandayDependencyInjector.instance.resolve());
}
