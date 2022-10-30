import 'dart:convert';

import 'package:flutter/services.dart';

class TwitchKeysReader {
  TwitchKeys? _twitchKeys;

  Future<TwitchKeys> getTwitchKeys() async {
    if (_twitchKeys == null) {
      String twitchKeysFileContent = await rootBundle.loadString('assets/keys/twitch_keys.json');
      var json = jsonDecode(twitchKeysFileContent);
      List<int> discordChannelIds = [];
      for (var discordChannelId in json['discordChannelIds']) {
        discordChannelIds.add(discordChannelId);
      }
      _twitchKeys = TwitchKeys(json['applicationClientId'], json['discordBotToken'], discordChannelIds);
    }
    return _twitchKeys!;
  }
}

class TwitchKeys {
  TwitchKeys(this.applicationClientId, this.discordBotToken, this.discordChannelIds);

  final String applicationClientId;
  final String discordBotToken;
  final Iterable<int> discordChannelIds;
}
