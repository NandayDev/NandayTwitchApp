import 'package:nanday_twitch_app/models/stream_online_info.dart';
import 'package:nanday_twitch_app/models/twitch_notification.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';

abstract class EventService {
  // Chat messages //
  void subscribeToChatMessageReceivedEvent(Function(TwitchChatMessage) function);

  void unsubscribeToChatMessageReceivedEvent(Function(TwitchChatMessage) function);

  void chatMessageReceived(TwitchChatMessage chatMessage);

  // Notifications //
  void subscribeToNotificationReceivedEvent(Function(TwitchNotification) function);

  void unsubscribeToNotificationReceivedEvent(Function(TwitchNotification) function);

  void notificationReceived(TwitchNotification notification);

  // Broadcast messages //
  void subscribeToBroadcastMessagesChangedEvent(Function(List<String>) function);

  void unsubscribeToBroadcastMessagesChangedEvent(Function(List<String>) function);

  void broadcastMessagesChanged(List<String> messages);

  // Channel online/offline //
  void subscribeToChannelOnlineChangedEvent(Future Function(StreamOnlineInfo) function);

  void unsubscribeToChannelOnlineChangedEvent(Future Function(StreamOnlineInfo) function);

  Future streamOnlineChanged(StreamOnlineInfo info);
}

class EventServiceImpl implements EventService {
  final List<Function(TwitchChatMessage)> _chatMessagesFunctions = [];
  final List<Function(TwitchNotification)> _notificationFunctions = [];
  final List<Function(List<String>)> _broadcastMessagesFunctions = [];
  final List<Future Function(StreamOnlineInfo)> _channelOnlineFunctions = [];

  @override
  void subscribeToChatMessageReceivedEvent(Function(TwitchChatMessage) function) {
    _chatMessagesFunctions.add(function);
  }

  @override
  void unsubscribeToChatMessageReceivedEvent(Function(TwitchChatMessage) function) {
    _chatMessagesFunctions.remove(function);
  }

  @override
  void chatMessageReceived(TwitchChatMessage chatMessage) {
    _triggerEvent(_chatMessagesFunctions, chatMessage);
  }

  @override
  void subscribeToNotificationReceivedEvent(Function(TwitchNotification) function) {
    _notificationFunctions.add(function);
  }

  @override
  void unsubscribeToNotificationReceivedEvent(Function(TwitchNotification) function) {
    _notificationFunctions.remove(function);
  }

  @override
  void notificationReceived(TwitchNotification notification) {
    _triggerEvent(_notificationFunctions, notification);
  }

  void _triggerEvent<T>(List<Function(T)> functions, T parameter) {
    for (var function in functions) {
      function(parameter);
    }
  }

  Future _triggerFutureEvent<T>(List<Future Function(T)> functions, T parameter) async {
    for (var function in functions) {
      await function(parameter);
    }
  }

  @override
  void subscribeToBroadcastMessagesChangedEvent(Function(List<String>) function) {
    _broadcastMessagesFunctions.add(function);
  }

  @override
  void unsubscribeToBroadcastMessagesChangedEvent(Function(List<String>) function) {
    _broadcastMessagesFunctions.remove(function);
  }

  @override
  void broadcastMessagesChanged(List<String> messages) {
    _triggerEvent(_broadcastMessagesFunctions, messages);
  }

  @override
  void subscribeToChannelOnlineChangedEvent(Future Function(StreamOnlineInfo) function) {
    _channelOnlineFunctions.add(function);
  }

  @override
  void unsubscribeToChannelOnlineChangedEvent(Future Function(StreamOnlineInfo) function) {
    _channelOnlineFunctions.remove(function);
  }

  @override
  Future streamOnlineChanged(StreamOnlineInfo info) {
    return _triggerFutureEvent(_channelOnlineFunctions, info);
  }
}
