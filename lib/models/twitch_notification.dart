// ignore_for_file: constant_identifier_names

class TwitchNotification {

  TwitchNotification(this.notificationType, this.username);

  final TwitchNotificationType notificationType;
  final String username;
}

enum TwitchNotificationType {
  NEW_FOLLOWER,
  SUBSCRIBE,
  RESUBSCRIBE,
  SUBSCRIPTION_GIFT,
  SUBSCRIPTION_GIFT_ANON,
  RAID
}

class TwitchRaidNotification extends TwitchNotification {

  TwitchRaidNotification(TwitchNotificationType notificationType, String username, this.raidersCount)
      : super(notificationType, username);

  final int raidersCount;
}