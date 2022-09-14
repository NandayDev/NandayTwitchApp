import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/services/text_to_speech_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';

class ChatMessageViewModel extends NandayViewModel {
  ChatMessageViewModel(this._textToSpeechService, this._chatMessage);

  bool isVoiceReading = false;

  final TextToSpeechService _textToSpeechService;
  final TwitchChatMessage _chatMessage;

  void read() async {
    isVoiceReading = true;
    notifyListeners();

    await _textToSpeechService.speak("${_chatMessage.author} says: ${_chatMessage.message}");

    isVoiceReading = false;
    notifyListeners();
  }

  static String chatMessageParamName = "chatMessage";
}
