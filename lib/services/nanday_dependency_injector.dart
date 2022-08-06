import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';
import 'package:nanday_twitch_app/ui/login/LoginPageViewModel.dart';
import 'package:nanday_twitch_app/ui/main/MainPageViewModel.dart';

class NandayDependencyInjector {
  ///
  /// Singleton instance
  ///
  static late NandayDependencyInjector instance = NandayDependencyInjector();

  final Injector _injector = _initializeInjector();

  ///
  /// Resolves given type to the implementation registered in the injector, if available
  ///
  T resolve<T>() {
    return _injector.get<T>();
  }

  static Injector _initializeInjector() {
    Injector injector = Injector();
    return injector
        .map<TwitchKeysReader>((injector) => TwitchKeysReader(), isSingleton: true)
        .map<TwitchAuthenticationService>((injector) => TwitchAuthenticationServiceImpl(injector.get()), isSingleton: true)
        .map<TwitchChatService>((injector) => TwitchChatServiceImpl(injector.get()), isSingleton: true)
        .map<LoginPageViewModel>((injector) => LoginPageViewModel(injector.get()))
        .map((injector) => MainPageViewModel(injector.get(), injector.get()));
  }
}
