import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/services/preferences_service.dart';

abstract class BroadcastMessagesService {
  ///
  /// Returns a list of all the saved broadcast messages
  ///
  Future<List<String>> getSavedMessages();

  ///
  /// Sets the broadcast messages to save
  ///
  Future setSavedMessages(List<String> messages);

  ///
  /// Actions called when the messages are updated
  ///
  List<Function()> onMessagesUpdated = [];
}

class BroadcastMessagesServiceImpl implements BroadcastMessagesService {
  BroadcastMessagesServiceImpl(this._preferencesService);

  final PreferencesService _preferencesService;

  @override
  Future<List<String>> getSavedMessages() async {
    return _preferencesService.getBroadcastMessages();
  }

  @override
  Future setSavedMessages(List<String> messages) async {
    await _preferencesService.setBroadcastMessages(messages); //todo handle error
    for (Function() messagesUpdatedFunction in onMessagesUpdated) {
      messagesUpdatedFunction();
    }
  }

  @override
  List<Function()> onMessagesUpdated = [];
}
