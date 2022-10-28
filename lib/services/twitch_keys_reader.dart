import 'dart:convert';

import 'package:flutter/services.dart';

class TwitchKeysReader {

  TwitchKeys? _twitchKeys;

  Future<TwitchKeys> getTwitchKeys() async {
    if (_twitchKeys == null) {
      String twitchKeysFileContent = await rootBundle.loadString('assets/keys/twitch_keys.json');
      var json = jsonDecode(twitchKeysFileContent);
      _twitchKeys = TwitchKeys(json['applicationClientId'], json['discordBotToken']);
    }
    return _twitchKeys!;
  }
}

class TwitchKeys {

  TwitchKeys(this.applicationClientId, this.discordBotToken);

  final String applicationClientId;
  final String discordBotToken;
}