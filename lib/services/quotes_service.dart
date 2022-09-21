import 'package:nanday_twitch_app/services/persistent_storage_service.dart';

abstract class QuoteService {

  ///
  /// Returns a random quote from the previously saved ones. If none available, returns null
  ///
  Future<String?> getRandomQuote();

  ///
  /// Gets a quote with given key, if available, or null
  ///
  Future<String?> getQuote(String key);

  ///
  /// Saves the quote and returns true if correctly saved
  ///
  Future<bool> saveQuote(String key, String value);
}

class QuoteServiceImpl implements QuoteService {

  QuoteServiceImpl(this._storageService);

  final PersistentStorageService _storageService;

  @override
  Future<String?> getQuote(String key) {
    return _storageService.getQuote(key);
  }

  @override
  Future<String?> getRandomQuote() {
    return _storageService.getRandomQuote();
  }

  @override
  Future<bool> saveQuote(String key, String value) {
    return _storageService.saveQuote(key, value);
  }

}