import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';

abstract class BroadcastMessagesService {
  Future initialize();
}

class BroadcastMessagesServiceImpl implements BroadcastMessagesService {
  BroadcastMessagesServiceImpl(this._twitchChatService, this._storageService, this._eventService, this._logger);

  final TwitchChatService _twitchChatService;
  final PersistentStorageService _storageService;
  final EventService _eventService;
  final LoggerService _logger;
  List<String> _broadcastMessages = [];
  int _broadcastMessagesIndex = 0;
  bool _isBroadcastMessagesLoopRunning = false;

  @override
  Future initialize() async {
    _updateBroadcastMessages();

    _eventService.subscribeToBroadcastMessagesChangedEvent((messages) {
      _updateBroadcastMessages();
    });
  }

  void _handleBroadcastMessages() async {
    if (_isBroadcastMessagesLoopRunning == true) {
      return;
    }

    int secondsBetweenMessages = await _storageService.getBroadcastDelay();
    Duration betweenMessagesDuration = Duration(seconds: secondsBetweenMessages);

    _isBroadcastMessagesLoopRunning = true;
    while (true) {
      if (_broadcastMessages.isEmpty) {
        _isBroadcastMessagesLoopRunning = false;
        _broadcastMessagesIndex = 0;
        return;
      }

      await Future.delayed(betweenMessagesDuration);

      String messageToBroadcast = _broadcastMessages[_broadcastMessagesIndex];
      _logger.i("Sending broadcast message $messageToBroadcast");
      if (!await _twitchChatService.sendChatMessage(messageToBroadcast)) {
        _logger.e("Issue sending the broadcast message!");
      }

      if (_broadcastMessagesIndex == _broadcastMessages.length - 1) {
        _broadcastMessagesIndex = 0;
      } else {
        _broadcastMessagesIndex++;
      }
    }
  }

  Future _updateBroadcastMessages() async {
    _broadcastMessages = await _storageService.getBroadcastMessages();
    _broadcastMessagesIndex = 0;
    _handleBroadcastMessages();
  }
}
