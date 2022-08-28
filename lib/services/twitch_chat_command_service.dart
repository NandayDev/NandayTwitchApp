import 'dart:collection';

import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/preferences_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';

abstract class TwitchChatCommandService {
  void initialize();
}

class TwitchChatCommandServiceImpl implements TwitchChatCommandService {
  TwitchChatCommandServiceImpl(this._twitchChatService, this._eventService, this._preferencesService, this._twitchKeysReader);

  final EventService _eventService;
  final TwitchChatService _twitchChatService;
  final PreferencesService _preferencesService;
  final TwitchKeysReader _twitchKeysReader;

  final HashSet<String> _greetedUsers = HashSet();

  static final Pattern _commandsPattern = RegExp('^!(\\w+)(?:\\s+(\\S+))?');
  final _dateFormat = DateFormat.yMMMMEEEEd();
  final _timeFormat = DateFormat.Hms();

  @override
  void initialize() async {
    TwitchKeys keys = await _twitchKeysReader.getTwitchKeys();
    _greetedUsers.add(keys.channelName);
    _greetedUsers.add(keys.botUsername);
    _eventService.subscribeToChatMessageReceivedEvent((chatMessage) async {
      await _handleCommandIfPresent(chatMessage);

      if (false == _greetedUsers.contains(chatMessage.author)) {
        _greetedUsers.add(chatMessage.author);
        _twitchChatService.sendChatMessage("Welcome ${chatMessage.author}! Have a seat!");
      }
    });
  }

  Future<bool> _handleCommandIfPresent(TwitchChatMessage chatMessage) async {
    Match? match = _commandsPattern.matchAsPrefix(chatMessage.message);
    if (match != null) {
      String? answer;
      switch (match.group(1)) {
        case 'what':
          answer = await _preferencesService.getWhatCommandContent('');
          if (answer.isEmpty) {
            answer = 'Sorry, "what" message not set. Ask the streamer to set it via !editcmd';
          }
          break;

        case 'time':
          DateTime currentDateTime = DateTime.now();
          answer = 'It is ${_dateFormat.format(currentDateTime)}, ${_timeFormat.format(currentDateTime)}';
          break;

        case 'editcmd':
          if (false == chatMessage.isFromStreamer) {
            answer = 'You\'re not authorized to edit commands.';
            break;
          }
          List<String>? otherParts = match.group(2)?.split(' ');
          if (otherParts != null && otherParts.isNotEmpty) {
            switch(otherParts[0]) {
              case 'what':
                String whatCommandContent = chatMessage.message.substring(14);
                if (await _preferencesService.setWhatCommandContent(whatCommandContent)) {
                  answer = 'Command successfully set!';
                }
                break;
            }
          }

          answer ??= 'Sorry, command unknown or an error occurred';
          break;

        default:
          break;
      }

      if (answer != null) {
        await _twitchChatService.answerChatMessage(chatMessage, answer);
        return true;
      } else {
        await _twitchChatService.answerChatMessage(chatMessage, 'Unrecognized command. Sorry!');
      }
    }

    return false;
  }
}
