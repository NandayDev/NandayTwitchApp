import 'dart:convert';

import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/ui/base/nanday_view_model.dart';


class LoginPageViewModel extends NandayViewModel {

  LoginPageViewModel(this._authenticationService);

  final TwitchAuthenticationService _authenticationService;

  ///
  /// Authenticates with Twitch backend to get an auth token
  ///
  Future<bool> authenticate() async {
    TwitchAuthenticationResult result = await _authenticationService.authenticate(Constants.CHAT_REDIRECT_PORT, Constants.CHAT_SCOPES);
    return result.token != null;
  }
}