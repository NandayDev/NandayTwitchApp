import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  late final textToSpeech = FlutterTts();

  Future speak(String text) async {
    await textToSpeech.awaitSpeakCompletion(true);
    var a = await textToSpeech.getLanguages;
    return textToSpeech.speak(text);
  }
}