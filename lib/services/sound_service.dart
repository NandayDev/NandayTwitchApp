
// ignore_for_file: constant_identifier_names

import 'package:audioplayers/audioplayers.dart';
import 'package:nanday_twitch_app/models/twitch_notification.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';


abstract class SoundService {
  void initialize();
}

class SoundServiceImpl implements SoundService {

  SoundServiceImpl(this._eventService, this._logger);

  final EventService _eventService;
  final LoggerService _logger;
  final _player = AudioPlayer();

  @override
  void initialize() {
    _eventService.subscribeToChatMessageReceivedEvent((chatMessage) {
      if (false == chatMessage.isFromStreamer && false == chatMessage.isFromStreamerBot) {
        _playFile(_Sound.NEW_MESSAGE);
      }
    });

    _eventService.subscribeToNotificationReceivedEvent((notification) {
      switch (notification.notificationType) {

        case TwitchNotificationType.NEW_FOLLOWER:
          _playFile(_Sound.NEW_FOLLOWER);
          break;
        case TwitchNotificationType.SUBSCRIBE:
        case TwitchNotificationType.RESUBSCRIBE:
        case TwitchNotificationType.SUBSCRIPTION_GIFT:
        case TwitchNotificationType.SUBSCRIPTION_GIFT_ANON:
          _playFile(_Sound.NEW_SUBSCRIBER);
          break;
        case TwitchNotificationType.RAID:
          _playFile(_Sound.RAID);
          break;
      }
    });
  }

  Future _playFile(_Sound sound) async {
    String? fileName;
    switch(sound) {
      case _Sound.NEW_MESSAGE:
        fileName = 'new_chat_message.wav';
        break;
      case _Sound.NEW_FOLLOWER:
        fileName = 'new_follower.wav';
        break;
      case _Sound.NEW_SUBSCRIBER:
        fileName = 'new_subscriber.wav';
        break;
      case _Sound.RAID:
        fileName = 'raid.wav';
        break;
    }

    if (fileName != null) {
      _logger.d('Playing $fileName');
      try {
        await _player.stop();
      } catch (e) {}
      try {
        await _player.play(AssetSource('sounds/$fileName'));
      } catch (e) {
        _logger.e('Couldn\'t play sound $fileName: $e');
      }
    }
  }

}

enum _Sound {
  NEW_MESSAGE,
  NEW_FOLLOWER,
  NEW_SUBSCRIBER,
  RAID
}