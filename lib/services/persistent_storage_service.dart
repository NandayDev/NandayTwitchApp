// ignore_for_file: constant_identifier_names

import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/models/profile.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:sqflite/sqflite.dart';

abstract class PersistentStorageService {
  /// Returns all profiles from the persistent storage
  Future<List<Profile>> getProfiles();

  /// Adds or edits given profile in the persistent storage
  Future<bool> addOrEditProfile(Profile profile);

  /// Deletes given profile in the persistent storage
  Future<bool> deleteProfile(Profile profile);

  /// Returns current profile being used
  Profile? currentProfile;

  // Broadcast delay //

  Future<int> getBroadcastDelay();

  Future<bool> setBroadcastDelay(int value);

  // Broadcast messages //

  Future<List<String>> getBroadcastMessages();

  Future<bool> setBroadcastMessages(List<String> messages);

  // Text to speech language //

  Future<String> getTextToSpeechLanguage(String defaultValue);

  Future<bool> setTextToSpeechLanguage(String value);

  // Content of "!what" command //

  Future<String> getWhatCommandContent(String defaultValue);

  Future<bool> setWhatCommandContent(String value);
}

class PersistentStorageServiceImpl implements PersistentStorageService {

  PersistentStorageServiceImpl(this._loggerService);

  final LoggerService _loggerService;

  @override
  Profile? currentProfile;

  @override
  Future<bool> addOrEditProfile(Profile profile) async {
    try {
      Map<String, dynamic> profileMap = _convertProfileToMap(profile);
      Database database = await _getDatabase();
      await database.insert(_PROFILES_TABLE_NAME, profileMap, conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } catch (e) {
      _loggerService.e("Error while saving profile: ${e.toString()}");
    }
    return false;
  }

  @override
  Future<bool> deleteProfile(Profile profile) async {
    if (profile.id == null || profile.id == 0) {
      _loggerService.w("Can't delete a profile with id ${profile.id ?? 'null'}");
      return false;
    }
    try {
      Database database = await _getDatabase();
      int result = await database.delete(_PROFILES_TABLE_NAME, where: '$_PROFILE_ID = ?', whereArgs: [profile.id]);
      _loggerService.d("deleteProfile: result from delete operation is $result");
      return result == 1;
    } catch (e) {
      _loggerService.e("Error while deleting profile: ${e.toString()}");
    }
    return false;
  }

  @override
  Future<int> getBroadcastDelay() async {
    String? settingValue = await _getSetting(_SETTING_KEY_BROADCAST_DELAY);
    if (settingValue == null) {
      return _DEFAULT_BROADCAST_DELAY_SECONDS;
    }
    return int.parse(settingValue);
  }

  @override
  Future<List<String>> getBroadcastMessages() async {
    Database database = await _getDatabase();
    var queryResults = await database.query(_BROADCAST_MESSAGES_TABLE_NAME, where: '$_BROADCAST_MESSAGE_PROFILE_ID = ${currentProfile!.id}');
    List<String> broadcastMessages = [];
    for (var queryResult in queryResults) {
      broadcastMessages.add(queryResult[_BROADCAST_MESSAGE_TEXT] as String);
    }
    return broadcastMessages;
  }

  @override
  Future<List<Profile>> getProfiles() async {
    Database database = await _getDatabase();
    var queryResults = await database.query(_PROFILES_TABLE_NAME);
    List<Profile> profiles = [];
    for (var queryResult in queryResults) {
      profiles.add(_convertMapToProfile(queryResult));
    }
    return profiles;
  }

  @override
  Future<String> getTextToSpeechLanguage(String defaultValue) {
    return _getStringSetting(_SETTING_KEY_TTS_LANGUAGE, defaultValue);
  }

  @override
  Future<String> getWhatCommandContent(String defaultValue) {
    return _getStringSetting(_SETTING_KEY_WHAT_COMMAND_CONTENT, defaultValue);
  }

  @override
  Future<bool> setBroadcastDelay(int value) {
    return _setSetting(_SETTING_KEY_BROADCAST_DELAY, value.toString());
  }

  @override
  Future<bool> setBroadcastMessages(List<String> messages) async {
    try {
      Database database = await _getDatabase();
      await database.transaction((txn) async {
        await txn.delete(_BROADCAST_MESSAGES_TABLE_NAME, where: '$_BROADCAST_MESSAGE_PROFILE_ID = ${currentProfile!.id}');
        for (String message in messages) {
          await txn.insert(_BROADCAST_MESSAGES_TABLE_NAME, {
            _BROADCAST_MESSAGE_PROFILE_ID : currentProfile!.id,
            _BROADCAST_MESSAGE_TEXT : message
          });
        }
      });
      return true;
    } catch (e) {
      _loggerService.e("Error while setting broadcast messages: ${e.toString()}");
    }
    return false;
  }

  @override
  Future<bool> setTextToSpeechLanguage(String value) {
    return _setSetting(_SETTING_KEY_TTS_LANGUAGE, value);

  }

  @override
  Future<bool> setWhatCommandContent(String value) {
    return _setSetting(_SETTING_KEY_WHAT_COMMAND_CONTENT, value);
  }

  Database? _database;

  Future<Database> _getDatabase() async {
    if (_database == null) {
      String databasePath = (await getApplicationDataDirectory()) + "\\nanday.db";
      _database = await openDatabase(databasePath, version: 1, onCreate: (db, version) {
        return db.execute('CREATE TABLE $_PROFILES_TABLE_NAME('
            '$_PROFILE_ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,'
            '$_PROFILE_CHANNEL_NAME TEXT NOT NULL,'
            '$_PROFILE_BOT_USERNAME TEXT NOT NULL,'
            '$_PROFILE_BROWSER_EXECUTABLE TEXT DEFAULT NULL);'
            'CREATE TABLE $_BROADCAST_MESSAGES_TABLE_NAME('
            '$_BROADCAST_MESSAGE_ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,'
            '$_BROADCAST_MESSAGE_PROFILE_ID INTEGER NOT NULL,'
            '$_BROADCAST_MESSAGE_TEXT TEXT NOT NULL,'
            'FOREIGN KEY($_BROADCAST_MESSAGE_PROFILE_ID) REFERENCES $_PROFILES_TABLE_NAME($_PROFILE_ID));'
            'CREATE TABLE $_SETTINGS_TABLE_NAME('
            '$_SETTING_PROFILE_ID INTEGER NOT NULL,'
            '$_SETTING_KEY TEXT NOT NULL,'
            '$_SETTING_VALUE TEXT NOT NULL,'
            'PRIMARY KEY ($_SETTING_PROFILE_ID, $_SETTING_KEY),'
            'FOREIGN KEY($_SETTING_PROFILE_ID) REFERENCES $_PROFILES_TABLE_NAME($_PROFILE_ID));');
      });
    }
    return _database!;
  }

  Map<String, dynamic> _convertProfileToMap(Profile profile) {
    Map<String, dynamic> map = {
      _PROFILE_CHANNEL_NAME: profile.channelName,
      _PROFILE_BOT_USERNAME: profile.botUsername,
      _PROFILE_BROWSER_EXECUTABLE: profile.browserExecutable
    };
    if (profile.id != null) {
      map[_PROFILE_ID] = profile.id;
    }
    return map;
  }

  Profile _convertMapToProfile(Map<String, Object?> queryResult) {
    return Profile(queryResult[_PROFILE_BOT_USERNAME] as String, queryResult[_PROFILE_CHANNEL_NAME] as String,
        queryResult.containsKey(_PROFILE_BROWSER_EXECUTABLE) ? queryResult[_PROFILE_BROWSER_EXECUTABLE] as String : null,
        id: queryResult.containsKey(_PROFILE_ID) ? queryResult[_PROFILE_ID] as int : null);
  }

  Future<String?> _getSetting(String settingKey) async {
    Database database = await _getDatabase();
    var queryResults = await database.query(_SETTINGS_TABLE_NAME,
        columns: [_SETTING_VALUE], where: '$_SETTING_PROFILE_ID = ${currentProfile!.id} AND $_SETTING_KEY = $settingKey', limit: 1);
    if (queryResults.isEmpty) {
      return null;
    }

    return queryResults[0][_SETTING_VALUE] as String;
  }

  Future<String> _getStringSetting(String settingKey, String defaultValue) async {
    String? settingValue = await _getSetting(settingKey);
    if (settingValue == null) {
      return defaultValue;
    }
    return settingValue;
  }

  Future<bool> _setSetting(String settingKey, String settingValue) async {
    try {
      Database database = await _getDatabase();
      await database.insert(_SETTINGS_TABLE_NAME,
          {
            _SETTING_PROFILE_ID: currentProfile!.id,
            _SETTING_KEY: settingKey,
            _SETTING_VALUE: settingValue
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } catch (e) {
      _loggerService.e("Failed setting save: $e");
    }
    return false;
  }

  static const String _PROFILES_TABLE_NAME = "profiles";
  static const String _PROFILE_ID = "id";
  static const String _PROFILE_CHANNEL_NAME = "channel_name";
  static const String _PROFILE_BOT_USERNAME = "bot_username";
  static const String _PROFILE_BROWSER_EXECUTABLE = "browser_executable";

  static const String _BROADCAST_MESSAGES_TABLE_NAME = "broadcast_messages";
  static const String _BROADCAST_MESSAGE_ID = "id";
  static const String _BROADCAST_MESSAGE_PROFILE_ID = "profile_id";
  static const String _BROADCAST_MESSAGE_TEXT = "text";

  static const String _SETTINGS_TABLE_NAME = "settings";
  static const String _SETTING_PROFILE_ID = "profile_id";
  static const String _SETTING_KEY = "key";
  static const String _SETTING_VALUE = "value";

  static const String _SETTING_KEY_BROADCAST_DELAY = "broadcast_delay";
  static const String _SETTING_KEY_TTS_LANGUAGE = "tts_language";
  static const String _SETTING_KEY_WHAT_COMMAND_CONTENT = "what_command_content";

  static const int _DEFAULT_BROADCAST_DELAY_SECONDS = 60 * 5;

}
