import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';

abstract class TwitchChatService {
  Future<bool> connect(String accessToken);

  Stream<TwitchChatMessage> getMessagesStream();
}

class TwitchChatMessage {
  TwitchChatMessage(this.author, this.message);

  final String author;
  final String message;
}

class TwitchChatServiceImpl implements TwitchChatService {
  bool? _connectedSuccessfully;
  IOWebSocketChannel? channel;
  final StreamController<TwitchChatMessage> _streamController = StreamController();
  final LineSplitter lineSplitter = const LineSplitter();

  @override
  Future<bool> connect(String accessToken) async {
    if (_connectedSuccessfully == true) {
      return true;
    }

    final webSocket = await WebSocket.connect('ws://irc-ws.chat.twitch.tv:80');

    channel = IOWebSocketChannel(webSocket);

    channel!.stream.listen(_parseChannelStreamMessages);

    channel!.sink.add('CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands');
    channel!.sink.add('PASS oauth:$accessToken');
    channel!.sink.add('NICK nandaydev');

    int retries = 0;

    while (_connectedSuccessfully == null && retries < 240) {
      retries++;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (_connectedSuccessfully == true) {
      channel!.sink.add('JOIN #nandaydev');
    }

    return _connectedSuccessfully == null ? false : _connectedSuccessfully!;
  }

  @override
  Stream<TwitchChatMessage> getMessagesStream() {
    return _streamController.stream;
  }

  void _parseChannelStreamMessages(event) {
    String channelMessage = event as String;

    //List<String> messages = lineSplitter.convert(channelMessage);
    Iterable<String> messages = LineSplitter.split(channelMessage);

    for (String message in messages) {
      print(message);

      _ParsedMessage? parsedMessage = _ParsedMessage.parse(message);
      if (parsedMessage == null) {
        continue;
      }

      // Ping-pong //
      switch(parsedMessage.command) {
        case 'PING':
          channel!.sink.add('PONG :tmi.twitch.tv');
          break;

        case 'PRIVMSG':
          String author = parsedMessage.prefix.split('!')[0];
          TwitchChatMessage chatMessage = TwitchChatMessage(author, parsedMessage.params[1]);
          _streamController.sink.add(chatMessage);
          break;

        case '001':
          _connectedSuccessfully = true;
          break;

        case 'NOTICE':
          if (message.contains('Login authentication failed')) {
            _connectedSuccessfully = false;
          }
          break;
      }
    }
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
        tags[pair[0]] = tag.substring(tag.indexOf("=") + 1) ?? "true";
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
