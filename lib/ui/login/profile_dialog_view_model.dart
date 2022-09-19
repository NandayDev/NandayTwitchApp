import 'package:nanday_twitch_app/models/profile.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';

class ProfileDialogViewModel extends NandayViewModel {

  ProfileDialogViewModel(this._storageService, Profile? profile) {
    _botUsername = profile?.botUsername ?? "";
    _channelName = profile?.channelName ?? "";
    _browserExecutablePath = profile?.browserExecutable;
    _profileId = profile?.id;
  }

  final PersistentStorageService _storageService;
  late final int? _profileId;

  bool _isLoading = false;
  bool get isLoading { return _isLoading; }

  bool get isSaveButtonEnabled { return _botUsername.isNotEmpty && _channelName.isNotEmpty; }
  bool? _profileSavedSuccessfully;
  bool? get profileSavedSuccessfully { return _profileSavedSuccessfully; }

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

  void saveProfile() async {
    Profile profile = Profile(botUsername, channelName, browserExecutablePath, id: _profileId);
    bool profileSaved = await _storageService.createOrEditProfile(profile);
    notifyPropertyChanged(() {
      _profileSavedSuccessfully = profileSaved;
    });
  }

  static const String profileParamName = "profile";
}