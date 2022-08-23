import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/services/broadcast_messages_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';

class BroadcastMessagesViewModel extends NandayViewModel {
  BroadcastMessagesViewModel(this._broadcastMessagesService);

  final BroadcastMessagesService _broadcastMessagesService;

  final List<String> messages = [];
  bool isLoading = true;
  bool isSaveButtonEnabled = true;

  void loadMessages() async {
    var broadcastMessages = await _broadcastMessagesService.getSavedMessages();
    notifyPropertyChanged(() {
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

  Future saveMessages() {
    notifyPropertyChanged(() {
      isSaveButtonEnabled = false;
    });
    return _broadcastMessagesService.setSavedMessages(messages);
  }
}
