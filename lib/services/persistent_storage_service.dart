// ignore_for_file: constant_identifier_names, prefer_conditional_assignment

import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/models/command.dart';
import 'package:nanday_twitch_app/models/db_stream.dart';
import 'package:nanday_twitch_app/models/profile.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tuple/tuple.dart';

abstract class PersistentStorageService {
  /// Returns all profiles from the persistent storage
  Future<List<Profile>> getProfiles();

  /// Adds or edits given profile in the persistent storage
  Future<bool> createOrEditProfile(Profile profile);

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

  // Starting and ending messages //
  Future<Tuple2<String, String>> getGoesOnlineAndOfflineMessages(String defaultValue);

  Future<bool> setGoesOnlineAndOfflineMessages(String startingMessage, String endingMessage);

  // Quotes //
  Future<String?> getRandomQuote();

  Future<String?> getQuote(String key);

  Future<bool> saveQuote(String key, String value);

  // Commands //
  Future<CustomCommand?> getCustomCommand(String keyword);

  Future<bool> saveCustomCommand(CustomCommand command);

  // Counts //
  Future<bool> addCountCommand(String key, String words);
  Future<Tuple2<int, String>?> getCountsForKeyAndIncrement(String key);
  Future<bool> resetAllCounts();

  // Streams //
  Future<DbStream?> getDbStreamByTwitchId(String twitchStreamId);

  Future<bool> createOrUpdateDbStream(DbStream dbStream);
}

class PersistentStorageServiceImpl implements PersistentStorageService {
  PersistentStorageServiceImpl(this._loggerService);

  final LoggerService _loggerService;
  Map<String, String>? __settingsCache;
  Database? _database;

  Future<Map<String, String>> get _settingsCache async {
    if (__settingsCache == null) {
      __settingsCache = await _initializeSettingsCache();
    }
    return __settingsCache!;
  }

  @override
  Profile? currentProfile;

  int get _profileId {
    return currentProfile!.id!;
  }

  @override
  Future<bool> createOrEditProfile(Profile profile) async {
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
    var queryResults = await database.query(_BROADCAST_MESSAGES_TABLE_NAME, where: '$_BROADCAST_MESSAGE_PROFILE_ID = $_profileId');
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
        await txn.delete(_BROADCAST_MESSAGES_TABLE_NAME, where: '$_BROADCAST_MESSAGE_PROFILE_ID = $_profileId');
        for (String message in messages) {
          await txn.insert(_BROADCAST_MESSAGES_TABLE_NAME, {_BROADCAST_MESSAGE_PROFILE_ID: _profileId, _BROADCAST_MESSAGE_TEXT: message});
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

  @override
  Future<Tuple2<String, String>> getGoesOnlineAndOfflineMessages(String defaultValue) async {
    String startingMessage = await _getStringSetting(_SETTING_KEY_TWITCH_ONLINE_MESSAGE, defaultValue);
    String endingMessage = await _getStringSetting(_SETTING_KEY_TWITCH_OFFLINE_MESSAGE, defaultValue);
    return Tuple2(startingMessage, endingMessage);
  }

  @override
  Future<bool> setGoesOnlineAndOfflineMessages(String onlineMessage, String offlineMessage) async {
    return await _setSetting(_SETTING_KEY_TWITCH_ONLINE_MESSAGE, onlineMessage) &&
        await _setSetting(_SETTING_KEY_TWITCH_OFFLINE_MESSAGE, offlineMessage);
  }

  @override
  Future<String?> getRandomQuote() async {
    // SELECT * FROM table ORDER BY RANDOM() LIMIT 1;
    Database database = await _getDatabase();
    List<Map<String, Object?>> queryResult =
        await database.query(_QUOTES_TABLE_NAME, where: '$_QUOTE_PROFILE_ID = $_profileId', orderBy: 'RANDOM()', limit: 1);
    return _firstQueryResultOrNull<String>(queryResult, _QUOTE_VALUE);
  }

  @override
  Future<String?> getQuote(String key) async {
    Database database = await _getDatabase();
    List<Map<String, Object?>> queryResult =
        await database.query(_QUOTES_TABLE_NAME, columns: [_QUOTE_VALUE], where: "$_QUOTE_PROFILE_ID = $_profileId AND $_QUOTE_KEY = '$key'");
    return _firstQueryResultOrNull<String>(queryResult, _QUOTE_VALUE);
  }

  @override
  Future<bool> saveQuote(String key, String value) async {
    try {
      Database database = await _getDatabase();
      await database.insert(_QUOTES_TABLE_NAME, {_QUOTE_PROFILE_ID: _profileId, _QUOTE_KEY: key, _QUOTE_VALUE: value},
          conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } catch (e) {
      _loggerService.e("Error while saving quote: ${e.toString()}");
    }
    return false;
  }

  @override
  Future<CustomCommand?> getCustomCommand(String keyword) async {
    try {
      Database database = await _getDatabase();
      List<Map<String, Object?>> queryResult = await database.query(_CUSTOM_COMMANDS_TABLE_NAME,
          columns: [_CUSTOM_COMMAND_CONTENT], where: "$_CUSTOM_COMMAND_PROFILE_ID = $_profileId AND $_CUSTOM_COMMAND_KEYWORD = '$keyword'");
      String? content = _firstQueryResultOrNull<String>(queryResult, _CUSTOM_COMMAND_CONTENT);
      if (content == null) {
        return null;
      }
      return CustomCommand(keyword, content);
    } catch (e) {
      _loggerService.e("getCustomCommand - failed: ${e.toString()}");
    }
    return null;
  }

  @override
  Future<bool> saveCustomCommand(CustomCommand command) async {
    try {
      Database database = await _getDatabase();
      await database.insert(_CUSTOM_COMMANDS_TABLE_NAME,
          {_CUSTOM_COMMAND_PROFILE_ID: _profileId, _CUSTOM_COMMAND_KEYWORD: command.keyword, _CUSTOM_COMMAND_CONTENT: command.content},
          conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } catch (e) {
      _loggerService.e("Error while saving quote: ${e.toString()}");
    }
    return false;
  }

  @override
  Future<bool> addCountCommand(String key, String words) async {
    try {
      Database database = await _getDatabase();
      List<Map<String, Object?>> queryResult = await database.query(_COUNTS_TABLE_NAME, columns: [_COUNT_NUMBER], where: "$_COUNT_KEY = '$key'");
      if (queryResult.isEmpty) {
        int insertResult = await database.insert(_COUNTS_TABLE_NAME, {_COUNT_KEY: key, _COUNT_NUMBER: 0, _COUNT_WORDS: words});
        // Command doesn't exist //
        return insertResult > 0;
      } else {
        return true;
      }
    } catch (e) {
      _loggerService.e("Error while getting counts for key and incrementing: ${e.toString()}");
    }
    return false;
  }

  @override
  Future<Tuple2<int, String>?> getCountsForKeyAndIncrement(String key) async {
    try {
      Database database = await _getDatabase();
      List<Map<String, Object?>> queryResult =
          await database.query(_COUNTS_TABLE_NAME, columns: [_COUNT_NUMBER, _COUNT_WORDS], where: "$_COUNT_KEY = '$key'");
      if (queryResult.isEmpty) {
        // Command doesn't exist //
        return null;
      }

      int currentCount = queryResult[0][_COUNT_NUMBER] as int;
      String words = queryResult[0][_COUNT_WORDS] as String;
      await database.update(_COUNTS_TABLE_NAME, {_COUNT_NUMBER: ++currentCount}, where: "$_COUNT_KEY = '$key'");
      return Tuple2(currentCount, words);
    } catch (e) {
      _loggerService.e("getCountsForKeyAndIncrement: Error while getting counts for key and incrementing: ${e.toString()}");
    }
    return null;
  }

  @override
  Future<bool> resetAllCounts() async {
    try {
      Database database = await _getDatabase();
      int deleted = await database.delete(_COUNTS_TABLE_NAME);
      _loggerService.d("resetAllCounts: deleted $deleted rows from $_COUNTS_TABLE_NAME table");
      return true;
    } catch (e) {
      _loggerService.e("resetAllCounts: Error while resetting all counts: ${e.toString()}");
      return false;
    }
  }

  @override
  Future<bool> createOrUpdateDbStream(DbStream dbStream) {
    var map = _convertDbStreamToMap(dbStream);
    return _insertInDatabase(map, _STREAMS_TABLE_NAME);
  }

  @override
  Future<DbStream?> getDbStreamByTwitchId(String twitchStreamId) async {
    Database database = await _getDatabase();
    List<Map<String, Object?>> queryResult = await database.query(_STREAMS_TABLE_NAME, where: "$_STREAM_TWITCH_ID = '$twitchStreamId' AND $_STREAM_PROFILE_ID = $_profileId");
    if (queryResult.isEmpty) {
      return null;
    }
    return _convertMapToStream(queryResult[0]);
  }

  T? _firstQueryResultOrNull<T>(List<Map<String, Object?>> queryResult, String columnName) {
    if (queryResult.isEmpty) {
      return null;
    }
    return queryResult[0][columnName] as T;
  }

  ///
  /// Attempts to insert given map in the table, returns true if successful
  ///
  Future<bool> _insertInDatabase(Map<String, Object?> map, String tableName, { ConflictAlgorithm conflictAlgorithm = ConflictAlgorithm.replace }) async {
    try {
      Database database = await _getDatabase();
      await database.insert(tableName, map, conflictAlgorithm: conflictAlgorithm);
      return true;
    } catch (e) {
      _loggerService.e("Error while inserting $map: ${e.toString()}");
    }
    return false;
  }

  Future<Database> _getDatabase() async {
    if (_database == null) {
      _loggerService.d("_getDatabase: Initializing database");
      try {
        sqfliteFfiInit();
      } catch (e) {
        _loggerService.e("_getDatabase: sqfliteFfiInit returned error: ${e.toString()}");
      }
      String databasePath = (await getApplicationDataDirectory()) + "\\nanday.ndb";
      _loggerService.d("_getDatabase: Path is $databasePath");
      _database = await databaseFactoryFfi.openDatabase(databasePath,
          options: OpenDatabaseOptions(
              version: 5,
              onUpgrade: (db, oldVersion, newVersion) async {
                if (oldVersion < 1) {
                  await db.execute('CREATE TABLE $_PROFILES_TABLE_NAME('
                      '$_PROFILE_ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,'
                      '$_PROFILE_CHANNEL_NAME TEXT NOT NULL,'
                      '$_PROFILE_BOT_USERNAME TEXT NOT NULL,'
                      '$_PROFILE_BROWSER_EXECUTABLE TEXT DEFAULT NULL,'
                      '$_PROFILE_BOT_LANGUAGE TEXT NOT NULL);'
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
                  await db.execute('CREATE TABLE $_QUOTES_TABLE_NAME('
                      '$_QUOTE_PROFILE_ID INTEGER NOT NULL,'
                      '$_QUOTE_KEY TEXT NOT NULL,'
                      '$_QUOTE_VALUE TEXT NOT NULL,'
                      'PRIMARY KEY ($_QUOTE_PROFILE_ID, $_QUOTE_KEY),'
                      'FOREIGN KEY($_QUOTE_PROFILE_ID) REFERENCES $_PROFILES_TABLE_NAME($_PROFILE_ID));');
                  await db.execute('CREATE TABLE $_CUSTOM_COMMANDS_TABLE_NAME('
                      '$_CUSTOM_COMMAND_PROFILE_ID INTEGER NOT NULL,'
                      '$_CUSTOM_COMMAND_KEYWORD TEXT NOT NULL,'
                      '$_CUSTOM_COMMAND_CONTENT TEXT NOT NULL,'
                      'PRIMARY KEY ($_CUSTOM_COMMAND_PROFILE_ID, $_CUSTOM_COMMAND_KEYWORD),'
                      'FOREIGN KEY($_CUSTOM_COMMAND_PROFILE_ID) REFERENCES $_PROFILES_TABLE_NAME($_PROFILE_ID));');
                }
                if (oldVersion < 2) {
                  await db.execute('CREATE TABLE $_COUNTS_TABLE_NAME('
                      '$_COUNT_KEY TEXT PRIMARY KEY NOT NULL,'
                      '$_COUNT_NUMBER TEXT NOT NULL);');
                }
                if (oldVersion < 3) {
                  await db.execute('DROP TABLE $_COUNTS_TABLE_NAME');
                  await db.execute('CREATE TABLE $_COUNTS_TABLE_NAME('
                      '$_COUNT_KEY TEXT PRIMARY KEY NOT NULL,'
                      '$_COUNT_NUMBER INTEGER NOT NULL);');
                }
                if (oldVersion < 4) {
                  await db.execute('ALTER TABLE $_COUNTS_TABLE_NAME ADD COLUMN $_COUNT_WORDS TEXT NOT NULL;');
                }
                if (oldVersion < 5) {
                  await db.execute('CREATE TABLE $_STREAMS_TABLE_NAME('
                      '$_STREAM_ID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,'
                      '$_STREAM_TWITCH_ID TEXT NOT NULL,'
                      '$_STREAM_PROFILE_ID INTEGER NOT NULL,'
                      '$_STREAM_TITLE TEXT NOT NULL,'
                      '$_STREAM_START_TIMESTAMP INTEGER NOT NULL,'
                      '$_STREAM_END_TIMESTAMP INTEGER DEFAULT NULL,'
                      '$_STREAM_FLAGS INTEGER NOT NULL,'
                      'FOREIGN KEY($_STREAM_PROFILE_ID) REFERENCES $_PROFILES_TABLE_NAME($_PROFILE_ID));');
                }
              }));
      _loggerService.d("_getDatabase: Database created");
    }
    return _database!;
  }

  Map<String, dynamic> _convertProfileToMap(Profile profile) {
    Map<String, dynamic> map = {
      _PROFILE_CHANNEL_NAME: profile.channelName,
      _PROFILE_BOT_USERNAME: profile.botUsername,
      _PROFILE_BROWSER_EXECUTABLE: profile.browserExecutable,
      _PROFILE_BOT_LANGUAGE: profile.botLanguage
    };
    if (profile.id != null) {
      map[_PROFILE_ID] = profile.id;
    }
    return map;
  }

  Profile _convertMapToProfile(Map<String, Object?> queryResult) {
    return Profile(
        queryResult[_PROFILE_BOT_USERNAME] as String,
        queryResult[_PROFILE_CHANNEL_NAME] as String,
        queryResult.containsKey(_PROFILE_BROWSER_EXECUTABLE) ? queryResult[_PROFILE_BROWSER_EXECUTABLE] as String? : null,
        queryResult[_PROFILE_BOT_LANGUAGE] as String,
        id: queryResult.containsKey(_PROFILE_ID) ? queryResult[_PROFILE_ID] as int : null);
  }

  Map<String, dynamic> _convertDbStreamToMap(DbStream stream) {
    return {
      _STREAM_ID: stream.databaseId,
      _STREAM_TWITCH_ID: stream.twitchId,
      _STREAM_PROFILE_ID: _profileId,
      _STREAM_TITLE: stream.title,
      _STREAM_START_TIMESTAMP: stream.startTimestampUtc,
      _STREAM_END_TIMESTAMP: stream.endTimestampUtc,
      _STREAM_FLAGS: stream.flags
    };
  }

  DbStream _convertMapToStream(Map<String, Object?> queryResult) {
    return DbStream(
        queryResult[_STREAM_TWITCH_ID] as String,
        queryResult[_STREAM_TITLE] as String,
        queryResult[_STREAM_START_TIMESTAMP] as int,
        queryResult[_STREAM_END_TIMESTAMP] as int?,
        databaseId: queryResult[_STREAM_ID] as int,
        flags: queryResult[_STREAM_FLAGS] as int
    );
  }

  Future<String?> _getSetting(String settingKey) async {
    Map<String, String> cache = await _settingsCache;
    return cache.containsKey(settingKey) ? cache[settingKey] : null;
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
      await database.insert(_SETTINGS_TABLE_NAME, {_SETTING_PROFILE_ID: _profileId, _SETTING_KEY: settingKey, _SETTING_VALUE: settingValue},
          conflictAlgorithm: ConflictAlgorithm.replace);
      __settingsCache?[settingKey] = settingValue;
      return true;
    } catch (e) {
      _loggerService.e("Failed setting save: $e");
    }
    return false;
  }

  Future<Map<String, String>> _initializeSettingsCache() async {
    Database database = await _getDatabase();
    var queryResults = await database.query(_SETTINGS_TABLE_NAME, where: '$_SETTING_PROFILE_ID = $_profileId');
    Map<String, String> settings = {};
    for (var queryResult in queryResults) {
      settings[queryResult[_SETTING_KEY] as String] = queryResult[_SETTING_VALUE] as String;
    }
    return settings;
  }

  static const String _PROFILES_TABLE_NAME = "profiles";
  static const String _PROFILE_ID = "id";
  static const String _PROFILE_CHANNEL_NAME = "channel_name";
  static const String _PROFILE_BOT_USERNAME = "bot_username";
  static const String _PROFILE_BROWSER_EXECUTABLE = "browser_executable";
  static const String _PROFILE_BOT_LANGUAGE = "bot_language";

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
  static const String _SETTING_KEY_TWITCH_ONLINE_MESSAGE = "twitch_online_message";
  static const String _SETTING_KEY_TWITCH_OFFLINE_MESSAGE = "twitch_offline_message";

  static const String _QUOTES_TABLE_NAME = "quotes";
  static const String _QUOTE_PROFILE_ID = "profile_id";
  static const String _QUOTE_KEY = "key";
  static const String _QUOTE_VALUE = "value";

  static const String _CUSTOM_COMMANDS_TABLE_NAME = "custom_commands";
  static const String _CUSTOM_COMMAND_PROFILE_ID = "profile_id";
  static const String _CUSTOM_COMMAND_KEYWORD = "keyword";
  static const String _CUSTOM_COMMAND_CONTENT = "content";

  static const String _COUNTS_TABLE_NAME = "counts";
  static const String _COUNT_KEY = "key";
  static const String _COUNT_NUMBER = "number";
  static const String _COUNT_WORDS = "words";

  static const String _STREAMS_TABLE_NAME = "streams";
  static const String _STREAM_ID = "id";
  static const String _STREAM_TWITCH_ID = "twitch_id";
  static const String _STREAM_PROFILE_ID = "profile_id";
  static const String _STREAM_TITLE = "title";
  static const String _STREAM_START_TIMESTAMP = "start_timestamp_utc";
  static const String _STREAM_END_TIMESTAMP = "end_timestamp_utc";
  static const String _STREAM_FLAGS = "flags";

  static const int _DEFAULT_BROADCAST_DELAY_SECONDS = 60 * 5;
}
