import 'package:nanday_twitch_app/services/text_to_speech_service.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';

import '../../services/twitch_chat_service.dart';

class MainPageViewModel extends NandayViewModel {
  MainPageViewModel(this._twitchChatService, this._authenticationService);

  final List<TwitchChatMessage> chatMessages = [];
  bool isLoading = true;

  final TwitchChatService _twitchChatService;
  final TwitchAuthenticationService _authenticationService;

  Future initialize() async {

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
}