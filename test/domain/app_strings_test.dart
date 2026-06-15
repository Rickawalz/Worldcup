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

  test('provides Amy\'s Calendar label in English and Spanish', () {
    expect(const AppStrings(Locale('en')).amysCalendar, "Amy's Calendar");
    expect(const AppStrings(Locale('es')).amysCalendar, "Amy's Calendar");
    expect(const AppStrings(Locale('en')).moreGames(2), '+2 more');
    expect(const AppStrings(Locale('es')).moreGames(2), '+2 más');
  });

  test('localizes PDF wallchart title and credit', () {
    expect(
      const AppStrings(Locale('en')).pdfBracketTitle('Ricky2026'),
      'Ricky2026 World Cup 2026 Bracket',
    );
    expect(
      const AppStrings(Locale('es')).pdfBracketTitle('Ricky2026'),
      'Bracket Mundial 2026 de Ricky2026',
    );
    expect(const AppStrings(Locale('en')).pdfAppCredit, 'App created by Ricky');
    expect(const AppStrings(Locale('es')).pdfAppCredit, 'App creada por Ricky');
  });

  test('provides standings legend copy in both languages', () {
    final english = const AppStrings(Locale('en'));
    final spanish = const AppStrings(Locale('es'));

    expect(english.standingsLegendTitle, 'What the columns mean');
    expect(english.standingsLegendEntries.first.abbr, 'P');
    expect(english.standingsLegendEntries.first.label, 'Played');
    expect(spanish.standingsLegendTitle, 'Significado de las columnas');
    expect(spanish.standingsLegendEntries.last.label, contains('Puntos'));
  });

  test('toggles app locale between English and Spanish', () {
    appLocaleNotifier.value = const Locale('en');

    toggleAppLocale();
    expect(appLocaleNotifier.value.languageCode, 'es');

    toggleAppLocale();
    expect(appLocaleNotifier.value.languageCode, 'en');
  });
}
