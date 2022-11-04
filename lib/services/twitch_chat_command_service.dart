import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:nanday_twitch_app/models/command.dart';
import 'package:nanday_twitch_app/models/result.dart';
import 'package:nanday_twitch_app/services/countdown_service.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/localizer.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/other_api_service.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/services/quotes_service.dart';
import 'package:nanday_twitch_app/services/session_repository.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';

abstract class TwitchChatCommandService {
  Future initialize();
}

class TwitchChatCommandServiceImpl implements TwitchChatCommandService {
  TwitchChatCommandServiceImpl(this._twitchChatService, this._eventService, this._storageService, this._quoteService, this._localizer,
      this._sessionRepository, this._otherApiService, this._loggerService, this._countdownService);

  final EventService _eventService;
  final TwitchChatService _twitchChatService;
  final PersistentStorageService _storageService;
  final CountdownService _countdownService;
  final QuoteService _quoteService;
  final Localizer _localizer;
  final SessionRepository _sessionRepository;
  final OtherApiService _otherApiService;
  final LoggerService _loggerService;

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
            message = Localizer.getStringWithPlaceholders(message, ["!quote $keyword"]);
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

        case 'addcountcmd':
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

          if (await _storageService.addCountCommand(key, content)) {
            answer = _localizer.localizations.countCommandCorrectlySaved;
          } else {
            answer = _localizer.localizations.databaseError;
          }

          break;

        case 'commands':
          // TODO list all available commands

          break;

        case 'uptime':
          DateTime? streamLiveSince = _sessionRepository.streamLiveSince;
          if (streamLiveSince == null) {
            answer = "Stream seems offline!";
          } else {
            Duration durationSinceLiveStarted = DateTime.now().difference(streamLiveSince);
            int hours = durationSinceLiveStarted.inHours;
            Duration minutesDuration = durationSinceLiveStarted - Duration(hours: hours);
            int minutes = minutesDuration.inMinutes;
            String hoursString = "$hours ${hours == 1 ? _localizer.localizations.hour : _localizer.localizations.hours}";
            String minutesString = "$minutes ${hours == 1 ? _localizer.localizations.minute : _localizer.localizations.minutes}";
            answer = Localizer.getStringWithPlaceholders(_localizer.localizations.streamLiveSinceMessage, [
              _sessionRepository.userDisplayName, hoursString, minutesString
            ]);
          }
          break;

        case 'lurk':
          // TODO play sound also

          break;

        case 'so':
          // Shout out
          //: !so and then the user and it will give a shout out to them - it will say please check out this person they were playing this game on twitch and this is the link
          //  exact text: Hey Guys, Check out ${1} who last played ${game ${1}} at https://twitch.tv/${channel ${1}}! HeartOtis
          break;

        case 'dadjoke':
          Result<String, String> apiResult = await _otherApiService.getRandomDadJoke();
          answer = apiResult.result;
          break;

        case 'snd':
          // TODO sounds

          break;

        // TODO redeem prizes?
        // Consider if using channel points or bot
        // Maybe a separate set of points for user to redeem (like support points, in my database)
        /*

GLHF Pledgedarksideup: i wanted to keep a timer - for when someone redeems for example, no swearing for 5mins - then the bot will count it down for me
GLHF Pledgedarksideup: but i never figured it out
GLHF Pledgedarksideup: maybe u can redeem maybe play with parrots for 5mins and keep it for 1 time use per stream

Or giveaways, prizes, etc
       */

        case 'countdown':
          if (false == chatMessage.isFromStreamer) {
            answer = _localizer.localizations.notAuthorized;
            break;
          }
          String? countdownDurationString = match.group(2);
          if (countdownDurationString == null) {
            _loggerService.e("countdownDurationString is null: group not found");
            answer = _localizer.localizations.invalidCommandSyntax;
            break;
          }
          Duration? countdownDuration = _countdownService.parseCountdownDurationString(countdownDurationString);
          if (countdownDuration == null) {
            _loggerService.e("countdownDuration is null: syntax of $countdownDurationString is invalid");
            answer = _localizer.localizations.invalidCommandSyntax;
            break;
          }
          _startCountdown(countdownDuration);
          answer = _localizer.localizations.countdownStarted;
          break;

        default:
          if (commandKeyword == null) {
            break;
          }
          CustomCommand? customCommand = await _storageService.getCustomCommand(commandKeyword);
          if (customCommand == null) {
            _loggerService.d("_handleCommandIfPresent: custom command with keyword $commandKeyword not found");
            var countsTuple = await _storageService.getCountsForKeyAndIncrement(commandKeyword);
            if (countsTuple != null) {
              int count = countsTuple.item1;
              String words = countsTuple.item2;
              answer = Localizer.getStringWithPlaceholders(_localizer.localizations.countMessage, [
                _sessionRepository.userDisplayName,
                words,
                count.toString(),
                count == 1 ? _localizer.localizations.timesSingular : _localizer.localizations.timesPlural
              ]);

              /*
              darksideup: you need a command to add and remove
              darksideup: add makessense and remove makessense by number
              darksideup: and reset completely
              darksideup: and !getmakessense so we can see how many there is already for the day
              darksideup: it must be chat commands
              darksideup: its easier to just make the bot do it the reset
              darksideup: every stream i used to reset my death counter for the bot
              darksideup: i would start the stream with !resetdead
              darksideup: that would work if you have a long stream a day
              darksideup: if you are getting disconnected a lot or have to go and come back
              darksideup: then the bot will reset right
              darksideup: and that days counter wont keep track properly
              darksideup: maybe you can have that as a toggle option for other users
              darksideup: but i know some streamers who always get disconnected but still want to try streaming
               */
            }
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

  void _startCountdown(Duration countdownDuration) async {
    _countdownService.awaitCountdown(countdownDuration);
    String chatMessage = Localizer.getStringWithPlaceholders(_localizer.localizations.countdownTimerIsUp, [countdownDuration.toString()]);
    _twitchChatService.sendChatMessage(chatMessage);
  }
}
