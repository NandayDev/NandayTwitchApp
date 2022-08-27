import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/services/broadcast_messages_service.dart';
import 'package:nanday_twitch_app/services/event_service.dart';
import 'package:nanday_twitch_app/services/preferences_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';

class BroadcastMessagesViewModel extends NandayViewModel {
  BroadcastMessagesViewModel(this._eventService, this._preferencesService);

  final EventService _eventService;
  final PreferencesService _preferencesService;

  final List<String> messages = [];
  bool isLoading = true;
  bool isSaveButtonEnabled = true;
  String broadcastDelay = "";

  void loadMessages() async {
    var broadcastMessages = await _preferencesService.getBroadcastMessages();
    String secondsBetweenMessagesFromPrefs = (await _preferencesService.getBroadcastDelay()).toString();
    notifyPropertyChanged(() {
      broadcastDelay = secondsBetweenMessagesFromPrefs;
      messages.addAll(broadcastMessages);
      isLoading = false;
    });
  }

  void messageEditedAtIndex(int index, String newText) {
    messages[index] = newText;
    // Avoids usage of the separator //
    if (newText.contains(Constants.BROADCAST_MESSAGES_SEPARATOR)) {
      notifyPropertyChanged(() {
        messages[index] = messages[index].replaceAll(Constants.BROADCAST_MESSAGES_SEPARATOR, '');
      });
    }
  }

  void messageDeletedAtIndex(int index) async {
    notifyPropertyChanged(() {
      messages.removeAt(index);
    });
  }

  void addNewMessage() {
    notifyPropertyChanged(() {
      messages.add('');
    });
  }

  Future saveMessages() async {
    notifyPropertyChanged(() {
      isSaveButtonEnabled = false;
    });
    await _preferencesService.setBroadcastMessages(messages);
    _eventService.broadcastMessagesChanged(messages);
  }

  Future<bool> saveBroadcastDelay(String text) async {
    int? seconds = int.tryParse(text);
    if (seconds == null) {
      return false;
    }
    await _preferencesService.setBroadcastDelay(seconds); //TODO handle error?
    return true;
  }
}
