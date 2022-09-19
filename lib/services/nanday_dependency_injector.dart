import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:nanday_twitch_app/services/broadcast_messages_service.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/services/sound_service.dart';
import 'package:nanday_twitch_app/services/text_to_speech_service.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_command_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';
import 'package:nanday_twitch_app/services/twitch_follower_poller.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';
import 'package:nanday_twitch_app/services/twitch_thanker.dart';
import 'package:nanday_twitch_app/ui/login/login_page_view_model.dart';
import 'package:nanday_twitch_app/ui/login/profile_dialog_view_model.dart';
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
        .map<EventService>((i) => EventServiceImpl(), isSingleton: true)
        .map<TwitchKeysReader>((i) => TwitchKeysReader(), isSingleton: true)
        .map<TwitchAuthenticationService>((i) => TwitchAuthenticationServiceImpl(i.get(), i.get()), isSingleton: true)
        .map<TwitchChatService>((i) => TwitchChatServiceImpl(i.get(), i.get(), i.get(), i.get()), isSingleton: true)
        .map<TextToSpeechService>((i) => TextToSpeechService(), isSingleton: true)
        .map<PersistentStorageService>((i) => PersistentStorageServiceImpl(i.get()), isSingleton: true)
        .map<BroadcastMessagesService>((i) => BroadcastMessagesServiceImpl(i.get(), i.get(), i.get(), i.get()), isSingleton: true)
        .map<LoggerService>((i) => LoggerServiceImpl(), isSingleton: true)
        .map<TwitchChatCommandService>((i) => TwitchChatCommandServiceImpl(i.get(), i.get(), i.get()), isSingleton: true)
        .map<TwitchFollowerPoller>((i) => TwitchFollowerPollerImpl(i.get(), i.get(), i.get(), i.get(), i.get()), isSingleton: true)
        .map<TwitchThanker>((i) => TwitchThankerImpl(i.get(), i.get()), isSingleton: true)
        .map<SoundService>((i) => SoundServiceImpl(i.get(), i.get()), isSingleton: true)

    // VIEW MODELS //
        // Login //
        .map<LoginPageViewModel>((i) => LoginPageViewModel(i.get(), i.get(), i.get()))
        // Main page //
        .map((i) => MainPageViewModel(i.get(), i.get(), i.get(), i.get(), i.get(), i.get(), i.get(), i.get(), i.get()))
        .mapWithParams<ChatMessageViewModel>((i, additionalParameters) => ChatMessageViewModel(i.get(), additionalParameters[ChatMessageViewModel.chatMessageParamName]))
        // Broadcast messages //
        .map<BroadcastMessagesViewModel>((i) => BroadcastMessagesViewModel(i.get(), i.get()))
        // Profile //
        .mapWithParams<ProfileDialogViewModel>((i, params) => ProfileDialogViewModel(i.get(), params[ProfileDialogViewModel.profileParamName]));
  }
}
