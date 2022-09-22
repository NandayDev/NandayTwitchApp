import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:nanday_twitch_app/models/command.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/localizer.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/services/quotes_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';

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
        String message = _localizer.localizations.welcomeMessage;
        message = Localizer.getStringWithPlaceholders(message, [chatMessage.author]);
        _twitchChatService.sendChatMessage(message);
      }
    });
  }

  Future<bool> _handleCommandIfPresent(TwitchChatMessage chatMessage) async {
    Match? match = _commandsPattern.matchAsPrefix(chatMessage.message);
    if (match != null) {
      String? answer;
      String? commandKeyword = match.group(1);
      switch (commandKeyword) {
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
            answer = _localizer.localizations.notAuthorized;
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
          String? keyword = match.group(2);
          if (keyword == null) {
            // User's asking for a random quote //
            String? randomQuote = await _quoteService.getRandomQuote();
            if (randomQuote == null) {
              answer = _localizer.localizations.noQuoteAvailable;
            } else {
              answer = randomQuote;
            }
          } else {
            // User's asking for a specific quote //
            String? quote = await _quoteService.getQuote(keyword);
            if (quote == null) {
              answer = _localizer.localizations.quoteNotFound;
            } else {
              answer = quote;
            }
          }
          break;

        case 'addquote':
          String? keyword = match.group(2);
          if (keyword == null) {
            answer = _localizer.localizations.invalidCommandSyntax;
            break;
          }
          String content = chatMessage.message.substring(1 + match.group(1)!.length + 1 + keyword.length + 1, chatMessage.message.length);
          if (await _storageService.saveQuote(keyword, content)) {
            String message = _localizer.localizations.quoteCorrectlySaved;
            message = Localizer.getStringWithPlaceholders(message, [ "!quote $keyword" ]);
            answer = message;
          } else {
            answer = _localizer.localizations.quoteNotSaved;
          }

          break;

        case 'addcmd':
          if (false == chatMessage.isFromStreamer) {
            answer = _localizer.localizations.notAuthorized;
            break;
          }
          String? key = match.group(2);
          if (key == null) {
            answer = _localizer.localizations.invalidCommandSyntax;
            break;
          }

          String content = chatMessage.message.substring(1 + match.group(1)!.length + 1 + key.length + 1, chatMessage.message.length);
          if (content.isEmpty) {
            answer = _localizer.localizations.invalidCommandSyntax;
            break;
          }
          CustomCommand customCommand = CustomCommand(key, content);
          if (await _storageService.saveCustomCommand(customCommand)) {
            answer = _localizer.localizations.customCommandCorrectlySaved;
          } else {
            answer = _localizer.localizations.customCommandNotSaved;
          }
          break;

        default:
          if (commandKeyword == null) {
            break;
          }
          CustomCommand? customCommand = await _storageService.getCustomCommand(commandKeyword);
          if (customCommand == null) {
            break;
          }
          answer = customCommand.content;
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
