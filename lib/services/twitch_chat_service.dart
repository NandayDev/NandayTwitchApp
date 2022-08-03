import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class TwitchChatService {


}

class TwitchChatServiceImpl implements TwitchChatService {
  Future connect(String accessToken) async {
    final channel = IOWebSocketChannel.connect(
      Uri.parse('ws://irc-ws.chat.twitch.tv:80'),
    );

    channel.stream.listen((event) {
      String a = event.toString();

    });
  }
}