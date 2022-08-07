import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/services/preferences_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';

class BroadcastMessagesViewModel extends NandayViewModel {

  BroadcastMessagesViewModel(this._preferencesService);

  final PreferencesService _preferencesService;

  final List<String> messages = [];
  bool isLoading = true;
  bool isSaveButtonEnabled = true;

  void loadMessages() async {
    String messagesFromPrefs = (await _preferencesService.getString(Constants.PSKEY_BROADCAST_MESSAGES)) ?? '';
    notifyPropertyChanged(() {
      messages.addAll(messagesFromPrefs.split(MESSAGES_SEPARATOR));
      isLoading = false;
    });
  }

  void messageEditedAtIndex(int index, String newText) {
    messages[index] = newText;
    // Avoids usage of the separator //
    if (newText.contains(MESSAGES_SEPARATOR)) {
      notifyPropertyChanged(() {
        messages[index] = messages[index].replaceAll(MESSAGES_SEPARATOR, '');
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

  Future saveMessages() {
    notifyPropertyChanged(() {
      isSaveButtonEnabled = false;
    });
    String messagesToSaveInPrefs = messages.join(MESSAGES_SEPARATOR);
    return _preferencesService.setString(Constants.PSKEY_BROADCAST_MESSAGES, messagesToSaveInPrefs);
  }

  static const String MESSAGES_SEPARATOR = '###*###';

}