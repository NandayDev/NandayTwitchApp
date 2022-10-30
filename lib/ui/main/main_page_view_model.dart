import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/services/text_to_speech_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';
import 'package:nanday_twitch_app/services/twitch_stream_poller.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';

class MainPageViewModel extends NandayViewModel {
  MainPageViewModel(this._twitchChatService, this._textToSpeechService, this._preferencesService, this._eventService, this._streamPoller);

  final List<TwitchChatMessage> chatMessages = [];
  bool isLoading = true;
  final List<String> languages = [];
  String? chosenLanguage;
  bool isLoadingLanguage = true;

  final TwitchChatService _twitchChatService;
  final TextToSpeechService _textToSpeechService;
  final PersistentStorageService _preferencesService;
  final EventService _eventService;
  final TwitchStreamPoller _streamPoller;

  void initialize() async {
    await _initializeTwitchChat();
    await _getAvailableLanguages();
    _streamPoller.startPollingTwitchStreams();
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
    await _twitchChatService.connect();
    isLoading = false;
    notifyListeners();

    // Chat messages //
    _eventService.subscribeToChatMessageReceivedEvent(onChatMessageReceived);
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
}
