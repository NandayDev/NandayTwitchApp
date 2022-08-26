import 'package:nanday_twitch_app/services/twitch_chat_service.dart';

abstract class TwitchChatUserService {
  void onMessageReceived(TwitchChatMessage message);
}

class TwitchChatUserServiceImpl implements TwitchChatUserService {

  TwitchChatUserServiceImpl(this._chatService);

  final TwitchChatService _chatService;

  final List<String> _greetedUsers = [];

  @override
  void onMessageReceived(TwitchChatMessage chatMessage) {
    if (false == _greetedUsers.contains(chatMessage.author)) {
      _greetedUsers.add(chatMessage.author);
      _chatService.sendChatMessage("Welcome ${chatMessage.author}! Have a seat!");
    }
  }
}