import 'package:nanday_twitch_app/models/twitch_notification.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';

abstract class TwitchThanker {
  void initialize();
}

class TwitchThankerImpl implements TwitchThanker {

  TwitchThankerImpl(this._eventService, this._twitchChatService);

  final EventService _eventService;
  final TwitchChatService _twitchChatService;

  @override
  void initialize() {
    // Notifications //
    _eventService.subscribeToNotificationReceivedEvent(_onNotificationReceived);
  }

  void _onNotificationReceived(TwitchNotification notification) {
    switch (notification.notificationType) {
      case TwitchNotificationType.NEW_FOLLOWER:
        _twitchChatService.sendChatMessage('Thank you ${notification.username} for following me!');
        break;
      case TwitchNotificationType.SUBSCRIBE:
        _twitchChatService.sendChatMessage('Thank you ${notification.username} for subscribing to the channel!');
        break;
      case TwitchNotificationType.RESUBSCRIBE:
        _twitchChatService.sendChatMessage('Thank you ${notification.username} for resubscribing to the channel!');
        break;
      case TwitchNotificationType.SUBSCRIPTION_GIFT:
        _twitchChatService.sendChatMessage('Thank you ${notification.username} for gifting subscribers to the channel!');
        break;
      case TwitchNotificationType.SUBSCRIPTION_GIFT_ANON:
        _twitchChatService.sendChatMessage('Thank you ${notification.username} for gifting subscribers to the channel!');
        break;
      case TwitchNotificationType.RAID:
      // TODO evaluate the raid size !
        _twitchChatService.sendChatMessage('Wow, so many people! Thank you ${notification.username} for raiding this channel!');
        break;
    }
  }
}