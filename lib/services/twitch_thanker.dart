import 'package:nanday_twitch_app/models/twitch_notification.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';

abstract class TwitchThanker {
  Future initialize();
}

class TwitchThankerImpl implements TwitchThanker {

  TwitchThankerImpl(this._eventService, this._twitchChatService);

  final EventService _eventService;
  final TwitchChatService _twitchChatService;

  @override
  Future initialize() async {
    // Notifications //
    _eventService.subscribeToNotificationReceivedEvent(_onNotificationReceived);
  }

  void _onNotificationReceived(TwitchNotification notification) {
    switch (notification.notificationType) {
      case TwitchNotificationType.NEW_FOLLOWER:
        _twitchChatService.sendChatMessage('New follower! Thank you ${notification.username} for joining this fellowship through the dark lands!');
        break;
      case TwitchNotificationType.SUBSCRIBE:
        _twitchChatService.sendChatMessage('Wow! Thank you ${notification.username} for financing this impossible journey!');
        break;
      case TwitchNotificationType.RESUBSCRIBE:
        _twitchChatService.sendChatMessage('Hooray! Thank you ${notification.username} for keeping the parrots well fed!');
        break;
      case TwitchNotificationType.SUBSCRIPTION_GIFT:
      case TwitchNotificationType.SUBSCRIPTION_GIFT_ANON:
        _twitchChatService.sendChatMessage('Santa is coming! Thank you ${notification.username} for keeping this infernal machine going!');
        break;
      case TwitchNotificationType.RAID:
        TwitchRaidNotification raidNotification = notification as TwitchRaidNotification;
        if (raidNotification.raidersCount > 4) {
          _twitchChatService.sendChatMessage('Wow, so many people! Thank you ${notification.username} for joining the dark side of programming!');
        } else {
          _twitchChatService.sendChatMessage('RAID INCOMING! Thank you ${notification.username} for joining the dark side of programming!');
        }
        break;
    }
  }
}