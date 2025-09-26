import 'package:family_app_flutter/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localizations expose English locale', () {
    // ANDROID-ONLY FIX: keep tests platform-agnostic while verifying localization setup.
    final bool hasEnglish = AppLocalizations.supportedLocales
        .any((Locale locale) => locale.languageCode == 'en');
    expect(hasEnglish, isTrue);
  });
}
