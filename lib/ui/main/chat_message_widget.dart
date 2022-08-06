import 'package:flutter/material.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';

class ChatMessageWidget extends StatefulWidget {
  const ChatMessageWidget(this._chatMessage, {Key? key}) : super(key: key);

  final TwitchChatMessage _chatMessage;

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget> {
  bool _isMouseOver = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onHover: (event) {
          setState(() {
            _isMouseOver = true;
          });
        },
        onExit: (event) {
          setState(() {
            _isMouseOver = false;
          });
        },
        child: Container(
            color: _isMouseOver ? Theme.of(context).highlightColor : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Row(
                children: [
                  Text(
                    widget._chatMessage.author,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Text(": "),
                  Text(widget._chatMessage.message)
                ],
              ),
            )));
  }
}
