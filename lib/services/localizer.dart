import 'dart:ui';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';

abstract class Localizer {

  Future initialize();

  AppLocalizations get localizations;
}

class LocalizerImpl implements Localizer {

  LocalizerImpl(this._storageService);

  final PersistentStorageService _storageService;
  Locale? _locale;

  @override
  Future initialize() async {
    String languageCode = await _storageService.getBotLanguage();
    _locale = Locale(languageCode);
  }

  @override
  AppLocalizations get localizations => lookupAppLocalizations(_locale!);

}