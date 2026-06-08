import '../domain/models.dart';

String? flagEmoji(Country country) {
  final code = _flagCodes[country.id];
  if (code == null) {
    return null;
  }
  return _regionalIndicatorFlag(code);
}

String _regionalIndicatorFlag(String countryCode) {
  const regionalIndicatorOffset = 0x1F1E6 - 0x41;
  return countryCode
      .toUpperCase()
      .codeUnits
      .map((unit) => String.fromCharCode(unit + regionalIndicatorOffset))
      .join();
}

const _flagCodes = <String, String>{
  'algeria': 'dz',
  'argentina': 'ar',
  'australia': 'au',
  'austria': 'at',
  'belgium': 'be',
  'bosnia_herzegovina': 'ba',
  'brazil': 'br',
  'cabo_verde': 'cv',
  'canada': 'ca',
  'colombia': 'co',
  'congo_dr': 'cd',
  'croatia': 'hr',
  'curacao': 'cw',
  'czech_republic': 'cz',
  'ecuador': 'ec',
  'egypt': 'eg',
  'france': 'fr',
  'germany': 'de',
  'ghana': 'gh',
  'haiti': 'ht',
  'iran': 'ir',
  'iraq': 'iq',
  'japan': 'jp',
  'jordan': 'jo',
  'mexico': 'mx',
  'morocco': 'ma',
  'netherlands': 'nl',
  'new_zealand': 'nz',
  'norway': 'no',
  'panama': 'pa',
  'paraguay': 'py',
  'portugal': 'pt',
  'qatar': 'qa',
  'saudi_arabia': 'sa',
  'senegal': 'sn',
  'south_africa': 'za',
  'south_korea': 'kr',
  'spain': 'es',
  'sweden': 'se',
  'switzerland': 'ch',
  'tunisia': 'tn',
  'turkey': 'tr',
  'uruguay': 'uy',
  'usa': 'us',
  'uzbekistan': 'uz',
};
