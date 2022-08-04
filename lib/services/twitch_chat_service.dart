import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class TwitchChatService {


}

class TwitchChatServiceImpl implements TwitchChatService {
  
  Future<bool> connect(String accessToken) async {
    final webSocket = await WebSocket.connect('ws://irc-ws.chat.twitch.tv:80');

    var channel = IOWebSocketChannel(webSocket);
    bool? connectedSuccessfully;

    channel.stream.listen((event) {
      String message = event as String;
      print(message.trim());

      if (message.contains('You are in a maze of twisty passages')) {
        connectedSuccessfully = true;
        return;
      }

      if (message.contains('Login authentication failed') || message.contains('Improperly formatted auth')) {
        connectedSuccessfully = false;
        return;
      }
    });

    channel.sink.add('CAP REQ :twitch.tv/membership twitch.tv/tags twitch.tv/commands');
    channel.sink.add('PASS oauth:$accessToken');
    channel.sink.add('NICK nandaydev');

    int retries = 0;

    while (connectedSuccessfully == null && retries < 240) {
      retries++;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (connectedSuccessfully == true) {
      channel.sink.add('JOIN #nandaydev');
      await Future.delayed(const Duration(milliseconds: 1000));
      channel.sink.add('PRIVMSG #nandaydev :This is a sample message');
    }

    return connectedSuccessfully == null ? false : connectedSuccessfully!;
  }
}