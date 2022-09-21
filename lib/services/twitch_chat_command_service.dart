import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:nanday_twitch_app/services/localizer.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/services/quotes_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';

abstract class TwitchChatCommandService {
  Future initialize();
}

class TwitchChatCommandServiceImpl implements TwitchChatCommandService {
  TwitchChatCommandServiceImpl(this._twitchChatService, this._eventService, this._storageService, this._quoteService, this._localizer);

  final EventService _eventService;
  final TwitchChatService _twitchChatService;
  final PersistentStorageService _storageService;
  final QuoteService _quoteService;
  final Localizer _localizer;

  final HashSet<String> _greetedUsers = HashSet();

  static final Pattern _commandsPattern = RegExp('^!(\\w+)(?:\\s+(\\S+))?');
  final _dateFormat = DateFormat.yMMMMEEEEd();
  final _timeFormat = DateFormat.Hms();

  @override
  Future initialize() async {
    _greetedUsers.add(_storageService.currentProfile!.channelName);
    _greetedUsers.add(_storageService.currentProfile!.botUsername);
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
          answer = await _storageService.getWhatCommandContent('');
          if (answer.isEmpty) {
            answer = _localizer.localizations.whatMessageNotSet;
          }
          break;

        case 'time':
          DateTime currentDateTime = DateTime.now();
          answer = 'It is ${_dateFormat.format(currentDateTime)}, ${_timeFormat.format(currentDateTime)}';
          break;

        case 'editcmd':
          if (false == chatMessage.isFromStreamer) {
            answer = _localizer.localizations.notAuthorizedToSetCommands;
            break;
          }
          List<String>? otherParts = match.group(2)?.split(' ');
          if (otherParts != null && otherParts.isNotEmpty) {
            switch (otherParts[0]) {
              case 'what':
                String whatCommandContent = chatMessage.message.substring(14);
                if (await _storageService.setWhatCommandContent(whatCommandContent)) {
                  answer = _localizer.localizations.commandSuccessfullySet;
                }
                break;
            }
          }

          answer ??= _localizer.localizations.commandUnknown;
          break;

        case 'quote':
          String? key = match.group(2);
          if (key == null) {
            // User's asking for a random quote //
            String? randomQuote = await _quoteService.getRandomQuote();
            if (randomQuote == null) {
              answer = _localizer.localizations.noQuoteAvailable;
            }
          }
          break;

        default:
          break;
      }

      if (answer != null) {
        await _twitchChatService.answerChatMessage(chatMessage, answer);
        return true;
      } else {
        await _twitchChatService.answerChatMessage(chatMessage, _localizer.localizations.unrecognizedCommand);
      }
    }

    return false;
  }
}
