import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';

abstract class TwitchChatCommandService {
  void initialize();
}

class TwitchChatCommandServiceImpl implements TwitchChatCommandService {
  TwitchChatCommandServiceImpl(this._chatService, this._eventService);

  final EventService _eventService;
  final TwitchChatService _chatService;

  final List<String> _greetedUsers = [];

  static final Pattern _commandsPattern = RegExp('^!(\\w+)(?:\\s+(\\S+))?');

  @override
  void initialize() {
    _eventService.subscribeToChatMessageReceivedEvent((chatMessage) {
      _handleCommandIfPresent(chatMessage);

      if (false == _greetedUsers.contains(chatMessage.author)) {
        _greetedUsers.add(chatMessage.author);
        _chatService.sendChatMessage("Welcome ${chatMessage.author}! Have a seat!");
      }
    });
  }

  bool _handleCommandIfPresent(TwitchChatMessage chatMessage) {
    Match? match = _commandsPattern.matchAsPrefix(chatMessage.message);
    if (match != null) {
      switch (match.group(1)) {
        case 'what':
          // TODO
          break;

        case 'time':
          // TODO
          break;

        default:
          return false;
      }

      return true;
    }

    return false;
  }
}
