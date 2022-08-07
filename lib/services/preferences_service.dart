import 'package:shared_preferences/shared_preferences.dart';

abstract class PreferencesService {
  ///
  /// Returns a string from the preferences
  ///
  Future<String?> getString(String key);

  ///
  /// Saves a string into the preferences
  ///
  Future setString(String key, String value);
}

class PreferencesServiceImpl implements PreferencesService {

  SharedPreferences? _prefs;

  @override
  Future<String?> getString(String key) async {
    SharedPreferences prefs = await _getSharedPreferences();
    return prefs.getString(key);
  }

  @override
  Future setString(String key, String value) async {
    SharedPreferences prefs = await _getSharedPreferences();
    prefs.setString(key, value);
  }

  Future<SharedPreferences> _getSharedPreferences() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }
}