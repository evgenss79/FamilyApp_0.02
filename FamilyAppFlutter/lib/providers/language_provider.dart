import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../l10n/app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider({Box<Object?>? box}) : _box = box {
    final savedCode = _box?.get(_languageCode) as String?;
    if (savedCode != null && _isSupported(savedCode)) {
      _locale = Locale(savedCode);
    }
  }

  static const _languageCode = 'language_code';
  final Box<Object?>? _box;
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (_locale == locale || !_isSupported(locale.languageCode)) {
      return;
    }
    _locale = locale;
    _box?.put(_languageCode, locale.languageCode);
    notifyListeners();
  }

  bool _isSupported(String code) {
    return AppLocalizations.supportedLocales
        .any((locale) => locale.languageCode == code);
  }
}
