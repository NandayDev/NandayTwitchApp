import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:nanday_twitch_app/services/broadcast_messages_service.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/sound_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_command_service.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/preferences_service.dart';
import 'package:nanday_twitch_app/services/text_to_speech_service.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';
import 'package:nanday_twitch_app/services/twitch_follower_poller.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';
import 'package:nanday_twitch_app/services/twitch_thanker.dart';
import 'package:nanday_twitch_app/ui/login/login_page_view_model.dart';
import 'package:nanday_twitch_app/ui/main/broadcast_messages_dialog/broadcast_messages_view_model.dart';
import 'package:nanday_twitch_app/ui/main/chat_message_view_model.dart';
import 'package:nanday_twitch_app/ui/main/main_page_view_model.dart';

class NandayDependencyInjector {
  ///
  /// Singleton instance
  ///
  static late NandayDependencyInjector instance = NandayDependencyInjector();

  final Injector _injector = _initializeInjector();

  ///
  /// Resolves given type to the implementation registered in the injector, if available
  ///
  T resolve<T>({Map<String, dynamic>? additionalParameters}) {
    return _injector.get<T>(additionalParameters: additionalParameters);
  }

  static Injector _initializeInjector() {
    Injector injector = Injector();
    return injector
    // SERVICES //
        .map<EventService>((injector) => EventServiceImpl(), isSingleton: true)
        .map<TwitchKeysReader>((injector) => TwitchKeysReader(), isSingleton: true)
        .map<TwitchAuthenticationService>((injector) => TwitchAuthenticationServiceImpl(injector.get()), isSingleton: true)
        .map<TwitchChatService>((injector) => TwitchChatServiceImpl(injector.get(), injector.get(), injector.get()), isSingleton: true)
        .map<TextToSpeechService>((injector) => TextToSpeechService(), isSingleton: true)
        .map<PreferencesService>((injector) => PreferencesServiceImpl(), isSingleton: true)
        .map<BroadcastMessagesService>((injector) => BroadcastMessagesServiceImpl(injector.get(), injector.get(), injector.get(), injector.get()), isSingleton: true)
        .map<LoggerService>((injector) => LoggerServiceImpl(), isSingleton: true)
        .map<TwitchChatCommandService>((injector) => TwitchChatCommandServiceImpl(injector.get(), injector.get(), injector.get(), injector.get()), isSingleton: true)
        .map<TwitchFollowerPoller>((injector) => TwitchFollowerPollerImpl(injector.get(), injector.get(), injector.get(), injector.get()), isSingleton: true)
        .map<TwitchThanker>((injector) => TwitchThankerImpl(injector.get(), injector.get()), isSingleton: true)
        .map<SoundService>((injector) => SoundServiceImpl(injector.get(), injector.get()), isSingleton: true)
    // VIEW MODELS //
      // Login //
        .map<LoginPageViewModel>((injector) => LoginPageViewModel(injector.get()))
      // Main page //
        .map((injector) => MainPageViewModel(injector.get(), injector.get(), injector.get(), injector.get(), injector.get(), injector.get(), injector.get(), injector.get(), injector.get(), injector.get()))
        .mapWithParams((injector, additionalParameters) => ChatMessageViewModel(injector.get(), additionalParameters[ChatMessageViewModel.chatMessageParamName]))
      // Broadcast messages //
        .map<BroadcastMessagesViewModel>((injector) => BroadcastMessagesViewModel(injector.get(), injector.get()));
  }
}
