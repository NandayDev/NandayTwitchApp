import 'package:nanday_twitch_app/models/twitch_notification.dart';
import 'package:nanday_twitch_app/services/broadcast_messages_service.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/preferences_service.dart';
import 'package:nanday_twitch_app/services/text_to_speech_service.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_command_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';

class MainPageViewModel extends NandayViewModel {
  MainPageViewModel(this._twitchChatService, this._twitchChatCommandService, this._broadcastMessagesService, this._authenticationService, this._textToSpeechService,
      this._preferencesService, this._eventService);

  final List<TwitchChatMessage> chatMessages = [];
  bool isLoading = true;
  final List<String> languages = [];
  String? chosenLanguage;
  bool isLoadingLanguage = true;

  final TwitchChatService _twitchChatService;
  final TwitchChatCommandService _twitchChatCommandService;
  final BroadcastMessagesService _broadcastMessagesService;
  final TwitchAuthenticationService _authenticationService;
  final TextToSpeechService _textToSpeechService;
  final PreferencesService _preferencesService;
  final EventService _eventService;

  void initialize() async {
    _twitchChatCommandService.initialize();
    await _initializeTwitchChat();
    await _getAvailableLanguages();
    _broadcastMessagesService.initialize();
  }

  void setLanguage(String language) async {
    notifyPropertyChanged(() {
      isLoadingLanguage = true;
    });

    await _textToSpeechService.changeLanguage(language);

    notifyPropertyChanged(() {
      isLoadingLanguage = false;
      chosenLanguage = language;
    });
  }

  Future _initializeTwitchChat() async {
    await _twitchChatService.connect(_authenticationService.accessToken!);
    isLoading = false;
    notifyListeners();

    // Chat messages //
    _eventService.subscribeToChatMessageReceivedEvent(onChatMessageReceived);

    // Notifications //
    _eventService.subscribeToNotificationReceivedEvent(onNotificationReceived);
  }

  Future _getAvailableLanguages() async {
    notifyPropertyChanged(() {
      isLoadingLanguage = true;
    });

    var ttsLanguages = await _textToSpeechService.getAvailableLanguagesInOS();
    String languageFromPreferences = await _preferencesService.getTextToSpeechLanguage("");

    notifyPropertyChangedAsync(() async {
      isLoadingLanguage = false;
      languages.addAll(ttsLanguages);
      if (languages.isNotEmpty) {
        String languageToUse;
        if (languageFromPreferences == "") {
          languageToUse = languages.firstWhere((element) => element == languageFromPreferences, orElse: () => languages[0]);
        } else {
          languageToUse = languages[0];
        }
        await _textToSpeechService.changeLanguage(languageToUse);
        await _preferencesService.setTextToSpeechLanguage(languageToUse);

        chosenLanguage = languageToUse;
      }
    });
  }

  void onChatMessageReceived(TwitchChatMessage chatMessage) {
    if (chatMessages.length == 50) {
      chatMessages.removeAt(0);
    }
    chatMessages.add(chatMessage);
    notifyListeners();
  }

  void onNotificationReceived(TwitchNotification notification) {
    switch (notification.notificationType) {
      case TwitchNotificationType.SUBSCRIBE:
        _twitchChatService.sendChatMessage('Thank you ${notification.username} for subscribing to the channel!');
        break;
      case TwitchNotificationType.RESUSCRIBE:
        _twitchChatService.sendChatMessage('Thank you ${notification.username} for resubscribing to the channel!');
        break;
      case TwitchNotificationType.SUBSCRIPTION_GIFT:
        _twitchChatService.sendChatMessage('Thank you ${notification.username} for gifting subscribers to the channel!');
        break;
      case TwitchNotificationType.SUBSCRIPTION_GIFT_ANON:
        _twitchChatService.sendChatMessage('Thank you ${notification.username} for gifting subscribers to the channel!');
        break;
      case TwitchNotificationType.RAID:
        // TODO evaluate the raid size !
        _twitchChatService.sendChatMessage('Wow, so many people! Thank you ${notification.username} for raiding this channel!');
        break;
    }
  }
}
