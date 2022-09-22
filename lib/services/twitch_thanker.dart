import 'package:nanday_twitch_app/models/twitch_notification.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/localizer.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';

abstract class TwitchThanker {
  Future initialize();
}

class TwitchThankerImpl implements TwitchThanker {
  TwitchThankerImpl(this._eventService, this._twitchChatService, this._localizer);

  final EventService _eventService;
  final TwitchChatService _twitchChatService;
  final Localizer _localizer;

  @override
  Future initialize() async {
    // Notifications //
    _eventService.subscribeToNotificationReceivedEvent(_onNotificationReceived);
  }

  void _onNotificationReceived(TwitchNotification notification) {
    switch (notification.notificationType) {
      case TwitchNotificationType.NEW_FOLLOWER:
        String message = _localizer.localizations.newFollowerThank;
        message = Localizer.getStringWithPlaceholders(message, [notification.username]);
        _twitchChatService.sendChatMessage(message);
        break;
      case TwitchNotificationType.SUBSCRIBE:
        String message = _localizer.localizations.newSubscriberThank;
        message = Localizer.getStringWithPlaceholders(message, [notification.username]);
        _twitchChatService.sendChatMessage(message);
        break;
      case TwitchNotificationType.RESUBSCRIBE:
        String message = _localizer.localizations.resubscriberThank;
        message = Localizer.getStringWithPlaceholders(message, [notification.username]);
        _twitchChatService.sendChatMessage(message);
        break;
      case TwitchNotificationType.SUBSCRIPTION_GIFT:
      case TwitchNotificationType.SUBSCRIPTION_GIFT_ANON:
        String message = _localizer.localizations.subscriptionGiftThank;
        message = Localizer.getStringWithPlaceholders(message, [notification.username]);
        _twitchChatService.sendChatMessage(message);
        break;
      case TwitchNotificationType.RAID:
        TwitchRaidNotification raidNotification = notification as TwitchRaidNotification;
        String message;
        if (raidNotification.raidersCount > 4) {
          message = _localizer.localizations.bigRaidThank;
        } else {
          message = _localizer.localizations.smallRaidThank;
        }
        message = Localizer.getStringWithPlaceholders(message, [notification.username]);
        _twitchChatService.sendChatMessage(message);
        break;
    }
  }
}
