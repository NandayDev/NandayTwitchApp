// ignore_for_file: constant_identifier_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class Constants {
  static const String REDIRECT_HOST = "localhost";
  static const int API_REDIRECT_PORT = 12893;
  static const int CHAT_REDIRECT_PORT = 12894;

  static const List<String> CHAT_SCOPES = ['channel:moderate', 'chat:edit', 'chat:read'];

  static const String BROADCAST_MESSAGES_SEPARATOR = '###*###';

// static const String API_REDIRECT_URI = "http://$REDIRECT_HOST:$API_REDIRECT_PORT";
// static const String CHAT_REDIRECT_URI = "http://$REDIRECT_HOST:$CHAT_REDIRECT_PORT";

}

String? _applicationDataDirectory;

Future<String> getApplicationDataDirectory() async {
  if (_applicationDataDirectory == null) {
    // var directory = await getApplicationSupportDirectory();
    WidgetsFlutterBinding.ensureInitialized();
    var directory = await getApplicationDocumentsDirectory();
    _applicationDataDirectory = "${directory.path}\\NandayTwitchBot";
    await Directory(_applicationDataDirectory!).create(recursive: true);
  }
  return _applicationDataDirectory!;
}
