import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/services/preferences_service.dart';
import 'package:nanday_twitch_app/services/text_to_speech_service.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';

class MainPageViewModel extends NandayViewModel {
  MainPageViewModel(this._twitchChatService, this._authenticationService, this._textToSpeechService, this._preferencesService);

  final List<TwitchChatMessage> chatMessages = [];
  bool isLoading = true;
  final List<String> languages = [];
  String? chosenLanguage;
  bool isLoadingLanguage = true;

  final TwitchChatService _twitchChatService;
  final TwitchAuthenticationService _authenticationService;
  final TextToSpeechService _textToSpeechService;
  final PreferencesService _preferencesService;

  void initialize() async {
    await _initializeTwitchChat();
    await _getAvailableLanguages();
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
    Stream<TwitchChatMessage> stream = _twitchChatService.getMessagesStream();
    stream.listen((chatMessage) {
      if (chatMessages.length == 50) {
        chatMessages.removeAt(0);
      }
      chatMessages.add(chatMessage);
      notifyListeners();
    });
  }

  Future _getAvailableLanguages() async {
    notifyPropertyChanged(() {
      isLoadingLanguage = true;
    });

    var ttsLanguages = await _textToSpeechService.getAvailableLanguagesInOS();
    String? languageFromPreferences = await _preferencesService.getString(Constants.PSKEY_CHOSEN_LANGUAGE);

    notifyPropertyChangedAsync(() async {
      isLoadingLanguage = false;
      languages.addAll(ttsLanguages);
      if (languages.isNotEmpty) {
        String languageToUse;
        if (languageFromPreferences != null) {
          languageToUse = languages.firstWhere((element) => element == languageFromPreferences, orElse: () => languages[0]);
        } else {
          languageToUse = languages[0];
        }
        await _preferencesService.setString(Constants.PSKEY_CHOSEN_LANGUAGE, languageToUse);

        chosenLanguage = languageToUse;
      }
    });
  }
}
