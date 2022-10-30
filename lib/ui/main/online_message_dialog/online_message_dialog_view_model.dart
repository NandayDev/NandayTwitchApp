import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';

class OnlineMessageDialogViewModel extends NandayViewModel {
  OnlineMessageDialogViewModel(this._storageService);

  final PersistentStorageService _storageService;

  String goesOnlineMessage = "";
  String goesOfflineMessage = "";

  bool isLoading = true;

  void loadMessages() async {
    var messages = await _storageService.getGoesOnlineAndOfflineMessages("");
    notifyPropertyChanged(() {
      goesOnlineMessage = messages.item1;
      goesOfflineMessage = messages.item2;
      isLoading = false;
    });
  }

  Future<bool> saveMessages() async {
    return _storageService.setGoesOnlineAndOfflineMessages(goesOnlineMessage, goesOfflineMessage);
  }
}
