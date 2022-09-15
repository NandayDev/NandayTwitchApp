import 'package:nanday_twitch_app/models/profile.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';

class ProfileDialogViewModel extends NandayViewModel {

  ProfileDialogViewModel(this._storageService, this.profile) {
    _botUsername = profile?.botUsername ?? "";
  }

  final PersistentStorageService _storageService;
  Profile? profile;

  late String _botUsername; // ...lol
  String get botUsername { return _botUsername; }
  set botUsername (String value) {
    _botUsername = value;
    // TODO
  }

  late String _channelName;
  String get channelName { return _channelName; }
  set channelName (String value) {
    _channelName = value;
    // TODO
  }

  String? _browserExecutablePath;
  String? get browserExecutablePath { return _browserExecutablePath; }
  set browserExecutablePath (String? value) {
    _browserExecutablePath = value;
    // TODO
  }

}