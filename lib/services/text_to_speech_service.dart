import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  late final textToSpeech = FlutterTts();

  Future speak(String text) async {
    await textToSpeech.awaitSpeakCompletion(true);
    await textToSpeech.getLanguages;
    return textToSpeech.speak(text);
  }

  Future<List<String>> getAvailableLanguagesInOS() async {
    List<String> languages = [];
    for (dynamic language in await textToSpeech.getLanguages) {
      languages.add(language);
    }
    return languages;
  }

  Future changeLanguage(String language) {
    return textToSpeech.setLanguage(language);
  }
}