import 'dart:convert';

import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/models/profile.dart';
import 'package:nanday_twitch_app/models/result.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';


class LoginPageViewModel extends NandayViewModel {

  LoginPageViewModel(this._storageService, this._authenticationService, this._loggerService);

  final PersistentStorageService _storageService;
  final TwitchAuthenticationService _authenticationService;
  final LoggerService _loggerService;

  bool isLoading = true;
  bool isLoginButtonEnabled = false;

  List<Profile> profiles = [];

  Profile? _selectedProfile;
  Profile? get selectedProfile { return _selectedProfile; }
  set selectedProfile (Profile? profile) {
    _selectedProfile = profile;
    _storageService.currentProfile = profile;
    notifyPropertyChanged(() {
      isLoginButtonEnabled = profile != null;
    });
  }

  EmptyResult<String>? _authenticationResult;
  EmptyResult<String>? get authenticationResult { return _authenticationResult; }

  void getProfiles() async {
    await _loggerService.ensureInitialized();
    profiles = await _storageService.getProfiles();

    notifyPropertyChanged(() {
      isLoading = false;
      selectedProfile = profiles.isNotEmpty ? profiles[0] : null;
      isLoginButtonEnabled = selectedProfile != null;
    });
  }

  ///
  /// Authenticates with Twitch backend to get an auth token
  ///
  void authenticate() async {
    notifyPropertyChanged(() {
      isLoading = true;
    });

    TwitchAuthenticationResult result = await _authenticationService.authenticate(Constants.CHAT_REDIRECT_PORT, Constants.CHAT_SCOPES);

    if (result.hasError) {
      notifyPropertyChanged(() {
        _authenticationResult = EmptyResult.withError(error: result.error);
      });
      return;
    }

    _storageService.currentProfile = selectedProfile;

    notifyPropertyChanged(() {
      _authenticationResult = EmptyResult.successful();
    });
  }
}