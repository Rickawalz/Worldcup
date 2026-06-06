import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/localization/app_strings.dart';

void main() {
  test('provides English and Spanish app copy', () {
    expect(
      const AppStrings(Locale('en')).buildFullBracket,
      'Build your full 2026 World Cup bracket',
    );
    expect(
      const AppStrings(Locale('es')).buildFullBracket,
      'Crea tu bracket completo del Mundial 2026',
    );
  });

  test('toggles app locale between English and Spanish', () {
    appLocaleNotifier.value = const Locale('en');

    toggleAppLocale();
    expect(appLocaleNotifier.value.languageCode, 'es');

    toggleAppLocale();
    expect(appLocaleNotifier.value.languageCode, 'en');
  });
}
