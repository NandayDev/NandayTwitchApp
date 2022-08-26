import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:nanday_twitch_app/models/twitch_notification.dart';
import 'package:nanday_twitch_app/services/broadcast_messages_service.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/preferences_service.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';
import 'package:web_socket_channel/io.dart';

abstract class TwitchChatService {
  ///
  /// Attempts to connect to the Twitch channel
  ///
  Future<bool> connect(String accessToken);

  ///
  /// Returns a stream of messages from Twitch chat
  ///
  Stream<TwitchChatMessage> getMessagesStream();

  ///
  /// Returns a stream of notifications from Twitch
  ///
  Stream<TwitchNotification> getNotificationsStream();

  ///
  /// Sends a message to Twitch chat
  ///
  Future<bool> sendChatMessage(String message);
}

class TwitchChatMessage {
  TwitchChatMessage(this.author, this.message);

  final String author;
  final String message;
}

class TwitchChatServiceImpl implements TwitchChatService {
  TwitchChatServiceImpl(this._keysReader, this._broadcastMessagesService, this._logger, this._preferencesService);

  final TwitchKeysReader _keysReader;
  final BroadcastMessagesService _broadcastMessagesService;
  final LoggerService _logger;
  final PreferencesService _preferencesService;

  bool? _connectedSuccessfully, _joinedRoomSuccessfully;

  IOWebSocketChannel? channel;
  final StreamController<TwitchChatMessage> _chatMessagesStreamController = StreamController();
  final StreamController<TwitchNotification> _notificationStreamController = StreamController();

  // Broadcast messages //
  List<String> _broadcastMessages = [];
  bool _isBroadcastMessagesLoopRunning = false;
  int _broadcastMessagesIndex = 0;

  @override
  Future<bool> connect(String accessToken) async {
    if (_connectedSuccessfully == true) {
      return true;
    }

    final webSocket = await WebSocket.connect('ws://irc-ws.chat.twitch.tv:80');
    TwitchKeys twitchKeys = await _keysReader.getTwitchKeys();

    channel = IOWebSocketChannel(webSocket);

    channel!.stream.listen(_parseChannelStreamMessages);

    channel!.sink.add('CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands');
    channel!.sink.add('PASS oauth:$accessToken');
    channel!.sink.add('NICK ${twitchKeys.botUsername}');

    int retries = 0;

    while (_connectedSuccessfully == null && retries < 240) {
      retries++;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_connectedSuccessfully == true) {
      channel!.sink.add('JOIN #${twitchKeys.channelName}');

      while (_joinedRoomSuccessfully == null && retries < 240) {
        retries++;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      _broadcastMessagesService.onMessagesUpdated.add(() {
        _updateBroadcastMessages();
      });
      await _updateBroadcastMessages();
      _handleBroadcastMessages();
    }

    return _connectedSuccessfully == null ? false : _connectedSuccessfully!;
  }



  @override
  Future<bool> sendChatMessage(String message) async {
    if (channel == null) {
      return false;
    }
    TwitchKeys twitchKeys = await _keysReader.getTwitchKeys();
    channel!.sink.add('PRIVMSG #${twitchKeys.channelName} :$message');
    return true;
  }

  @override
  Stream<TwitchChatMessage> getMessagesStream() {
    return _chatMessagesStreamController.stream;
  }

  @override
  Stream<TwitchNotification> getNotificationsStream() {
    return _notificationStreamController.stream;
  }

  void _parseChannelStreamMessages(event) {
    String channelMessage = event as String;

    Iterable<String> messages = LineSplitter.split(channelMessage);

    for (String message in messages) {
      _logger.d(message);

      _ParsedMessage? parsedMessage = _ParsedMessage.parse(message);
      if (parsedMessage == null) {
        continue;
      }

      // Ping-pong //
      switch (parsedMessage.command) {
        case 'PING':
          channel!.sink.add('PONG :tmi.twitch.tv');
          break;

        case 'PRIVMSG':
          String author = parsedMessage.prefix.split('!')[0];
          TwitchChatMessage chatMessage = TwitchChatMessage(author, parsedMessage.params[1]);
          _chatMessagesStreamController.sink.add(chatMessage);
          break;

        case 'USERNOTICE':
          String messageTypeId = parsedMessage.tags['msg-id'];
          TwitchNotificationType? notificationType;
          switch (messageTypeId) {
            case 'sub':
              notificationType = TwitchNotificationType.SUBSCRIBE;
              break;

            case 'resub':
              notificationType = TwitchNotificationType.RESUSCRIBE;
              break;

            case 'raid':
              notificationType = TwitchNotificationType.RAID;
              break;

            case 'subgift':
              notificationType = TwitchNotificationType.SUBSCRIPTION_GIFT;
              break;

            case 'anonsubgift':
              notificationType = TwitchNotificationType.SUBSCRIPTION_GIFT_ANON;
              break;
          }
          if (notificationType != null) {
            String username = parsedMessage.tags['display-name'];
            TwitchNotification notification = TwitchNotification(notificationType, username);
            _notificationStreamController.sink.add(notification);
          }

          break;

        case '001':
          _connectedSuccessfully = true;
          break;

        case 'ROOMSTATE':
          _joinedRoomSuccessfully = true;
          break;

        case 'NOTICE':
          if (message.contains('Login authentication failed')) {
            _connectedSuccessfully = false;
          }
          break;
      }
    }
  }

  void _handleBroadcastMessages() async {
    if (_isBroadcastMessagesLoopRunning == true) {
      return;
    }

    int secondsBetweenMessages = await _preferencesService.getBroadcastDelay();
    Duration betweenMessagesDuration = Duration(seconds: secondsBetweenMessages);

    _isBroadcastMessagesLoopRunning = true;
    while (true) {
      await Future.delayed(betweenMessagesDuration);
      if (_broadcastMessages.isEmpty) {
        _isBroadcastMessagesLoopRunning = false;
        _broadcastMessagesIndex = 0;
        return;
      }

      String messageToBroadcast = _broadcastMessages[_broadcastMessagesIndex];
      _logger.i("Sending message $messageToBroadcast");
      if (!await sendChatMessage(messageToBroadcast)) {
        _logger.e("Issue sending the chat message!");
      }

      if (_broadcastMessagesIndex == _broadcastMessages.length - 1) {
        _broadcastMessagesIndex = 0;
      } else {
        _broadcastMessagesIndex++;
      }

      await Future.delayed(betweenMessagesDuration);
    }
  }

  Future _updateBroadcastMessages() async {
    _broadcastMessages = await _broadcastMessagesService.getSavedMessages();
    _broadcastMessagesIndex = 0;
    _handleBroadcastMessages();
  }
}

class _ParsedMessage {
  final String raw;
  final Map<String, dynamic> tags;
  final String prefix;
  final String command;
  final List<String> params;

  _ParsedMessage(
    this.raw,
    this.tags,
    this.prefix,
    this.command,
    this.params,
  );

  static _ParsedMessage? parse(String data) {
    // Parse a message.
    //
    // Based on TMI.js version at
    // https://github.com/tmijs/tmi.js/blob/427704002e26bff22bbbbb52cee6ca124ee08525/lib/client.js#L89

    var position = 0;
    var nextspace = 0;

    Map<String, dynamic> tags = {};
    String prefix = "";
    String command = "";
    List<String> params = [];

    // The first thing we check for is IRCv3.2 message tags.
    // http://ircv3.atheme.org/specification/message-tags-3.2
    if (data.codeUnitAt(0) == 64) {
      var nextspace = data.indexOf(" ");

      // Malformed IRC message..
      if (nextspace == -1) {
        return null;
      }

      // Tags are split by a semi colon..
      var rawTags = data.substring(1, nextspace).split(";");

      for (var i = 0; i < rawTags.length; i++) {
        // Tags delimited by an equals sign are key=value tags.
        // If there's no equals, we assign the tag a value of true.
        var tag = rawTags[i];
        var pair = tag.split("=");
        tags[pair[0]] = tag.substring(tag.indexOf("=") + 1);
      }

      position = nextspace + 1;
    }

    // Skip any trailing whitespace..
    while (data.codeUnitAt(position) == 32) {
      position++;
    }

    // Extract the message's prefix if present. Prefixes are prepended with a colon..
    if (data.codeUnitAt(position) == 58) {
      nextspace = data.indexOf(" ", position);

      // If there's nothing after the prefix, deem this message to be malformed.
      if (nextspace == -1) {
        return null;
      }

      prefix = data.substring(position + 1, nextspace);
      position = nextspace + 1;

      // Skip any trailing whitespace..
      while (data.codeUnitAt(position) == 32) {
        position++;
      }
    }

    nextspace = data.indexOf(" ", position);

    // If there's no more whitespace left, extract everything from the
    // current position to the end of the string as the command..
    if (nextspace == -1) {
      if (data.length > position) {
        command = data.substring(position);
        return _ParsedMessage(
          data,
          tags,
          prefix,
          command,
          params,
        );
      }
      return null;
    }

    // Else, the command is the current position up to the next space. After
    // that, we expect some parameters.
    command = data.substring(position, nextspace);

    position = nextspace + 1;

    // Skip any trailing whitespace..
    while (data.codeUnitAt(position) == 32) {
      position++;
    }

    while (position < data.length) {
      nextspace = data.indexOf(" ", position);

      // If the character is a colon, we've got a trailing parameter.
      // At this point, there are no extra params, so we push everything
      // from after the colon to the end of the string, to the params array
      // and break out of the loop.
      if (data.codeUnitAt(position) == 58) {
        params.add(data.substring(position + 1));
        break;
      }

      // If we still have some whitespace...
      if (nextspace != -1) {
        // Push whatever's between the current position and the next
        // space to the params array.
        params.add(data.substring(position, nextspace));
        position = nextspace + 1;

        // Skip any trailing whitespace and continue looping.
        while (data.codeUnitAt(position) == 32) {
          position++;
        }

        continue;
      }

      // If we don't have any more whitespace and the param isn't trailing,
      // push everything remaining to the params array.
      if (nextspace == -1) {
        params.add(data.substring(position));
        break;
      }
    }

    return _ParsedMessage(
      data,
      tags,
      prefix,
      command,
      params,
    );
  }
}
