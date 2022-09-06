import 'dart:convert';

import 'package:flutter/services.dart';

class TwitchKeysReader {

  TwitchKeys? _twitchKeys;

  Future<TwitchKeys> getTwitchKeys() async {
    if (_twitchKeys == null) {
      String twitchKeysFileContent = await rootBundle.loadString('assets/keys/twitch_keys.json');
      var json = jsonDecode(twitchKeysFileContent);
      _twitchKeys = TwitchKeys(json['applicationClientId'], json['botUsername'], json['channelName'], json['browserExecutable']);
    }
    return _twitchKeys!;
  }
}

class TwitchKeys {

  TwitchKeys(this.applicationClientId, this.botUsername, this.channelName, this.browserExecutable);

  final String applicationClientId;
  final String botUsername;
  final String channelName;
  final String? browserExecutable;

}