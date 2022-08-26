// ignore_for_file: constant_identifier_names

import 'package:nanday_twitch_app/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class PreferencesService {

  // Broadcast delay //

  Future<int> getBroadcastDelay();

  Future<bool> setBroadcastDelay(int value);

  // Broadcast messages //

  Future<List<String>> getBroadcastMessages();

  Future<bool> setBroadcastMessages(List<String> messages);

  // Text to speech language //

  Future<String> getTextToSpeechLanguage(String defaultValue);

  Future<bool> setTextToSpeechLanguage(String value);
}

class PreferencesServiceImpl implements PreferencesService {

  SharedPreferences? _prefs;

  @override
  Future<int> getBroadcastDelay() {
    return _getInt(_KEY_BROADCAST_DELAY_SECONDS, _DEFAULT_BROADCAST_DELAY_SECONDS);
  }

  @override
  Future<bool> setBroadcastDelay(int value) {
    return _setInt(_KEY_BROADCAST_DELAY_SECONDS, value);
  }

  @override
  Future<List<String>> getBroadcastMessages() async {
    String broadcastMessagesFromPrefs = await _getString(_KEY_BROADCAST_MESSAGES, "");
    return broadcastMessagesFromPrefs.split(Constants.BROADCAST_MESSAGES_SEPARATOR);
  }

  @override
  Future<bool> setBroadcastMessages(List<String> messages) {
    String broadcastMessagesForPrefs = messages.join(Constants.BROADCAST_MESSAGES_SEPARATOR);
    return _setString(_KEY_BROADCAST_MESSAGES, broadcastMessagesForPrefs);
  }

  @override
  Future<String> getTextToSpeechLanguage(String defaultValue) {
    return _getString(_KEY_CHOSEN_LANGUAGE, defaultValue);
  }

  @override
  Future<bool> setTextToSpeechLanguage(String value) {
    return _setString(_KEY_CHOSEN_LANGUAGE, value);
  }

  Future<SharedPreferences> _getSharedPreferences() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String> _getString(String key, String defaultValue) async {
    SharedPreferences prefs = await _getSharedPreferences();
    return prefs.getString(key) ?? defaultValue;
  }

  Future<bool> _setString(String key, String value) async {
    SharedPreferences prefs = await _getSharedPreferences();
    return prefs.setString(key, value);
  }

  Future<int> _getInt(String key, int defaultValue) async {
    SharedPreferences prefs = await _getSharedPreferences();
    return prefs.getInt(key) ?? defaultValue;
  }

  Future<bool> _setInt(String key, int value) async {
    SharedPreferences prefs = await _getSharedPreferences();
    return prefs.setInt(key, value);
  }

  // Preferences service keys //
  static const String _KEY_CHOSEN_LANGUAGE = "chosen_language";
  static const String _KEY_BROADCAST_MESSAGES = "broadcast_messages";
  static const String _KEY_BROADCAST_DELAY_SECONDS = "seconds_between_broadcast_messages";
  static const int _DEFAULT_BROADCAST_DELAY_SECONDS = 60 * 5;
}