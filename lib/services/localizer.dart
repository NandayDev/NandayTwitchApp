import 'dart:ui';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';

abstract class Localizer {
  Future initialize();

  AppLocalizations get localizations;

  static String getStringWithPlaceholders(String originalString, List<String> placeholdersSubstitutes) {
    for (int i = 0; i < placeholdersSubstitutes.length; i++) {
      originalString = originalString.replaceAll("{$i}", placeholdersSubstitutes[i]);
    }
    return originalString;
  }
}

class LocalizerImpl implements Localizer {
  LocalizerImpl(this._storageService);

  final PersistentStorageService _storageService;
  Locale? _locale;

  @override
  Future initialize() async {
    String languageCode = _storageService.currentProfile!.botLanguage;
    _locale = Locale(languageCode);
  }

  @override
  AppLocalizations get localizations => lookupAppLocalizations(_locale!);
}
