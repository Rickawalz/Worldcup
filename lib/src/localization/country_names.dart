import 'package:flutter/widgets.dart';

import '../domain/models.dart';
import 'app_strings.dart';

String countryDisplayName(BuildContext context, Country country) {
  return countryDisplayNameForLocale(AppLocaleScope.localeOf(context), country);
}

String countryDisplayNameForLocale(Locale locale, Country country) {
  if (locale.languageCode != 'es') {
    return country.name;
  }
  return _spanishCountryNames[country.id] ?? country.name;
}

const _spanishCountryNames = <String, String>{
  'argentina': 'Argentina',
  'algeria': 'Argelia',
  'australia': 'Australia',
  'austria': 'Austria',
  'belgium': 'Bélgica',
  'bosnia_herzegovina': 'Bosnia y Herzegovina',
  'brazil': 'Brasil',
  'cabo_verde': 'Cabo Verde',
  'cameroon': 'Camerún',
  'canada': 'Canadá',
  'chile': 'Chile',
  'colombia': 'Colombia',
  'congo_dr': 'Congo RD',
  'costa_rica': 'Costa Rica',
  'croatia': 'Croacia',
  'curacao': 'Curazao',
  'czech_republic': 'República Checa',
  'denmark': 'Dinamarca',
  'ecuador': 'Ecuador',
  'egypt': 'Egipto',
  'england': 'Inglaterra',
  'france': 'Francia',
  'germany': 'Alemania',
  'ghana': 'Ghana',
  'haiti': 'Haití',
  'iran': 'Irán',
  'iraq': 'Irak',
  'italy': 'Italia',
  'jamaica': 'Jamaica',
  'japan': 'Japón',
  'jordan': 'Jordania',
  'mexico': 'México',
  'morocco': 'Marruecos',
  'netherlands': 'Países Bajos',
  'new_zealand': 'Nueva Zelanda',
  'nigeria': 'Nigeria',
  'norway': 'Noruega',
  'panama': 'Panamá',
  'paraguay': 'Paraguay',
  'peru': 'Perú',
  'poland': 'Polonia',
  'portugal': 'Portugal',
  'qatar': 'Catar',
  'saudi_arabia': 'Arabia Saudita',
  'scotland': 'Escocia',
  'senegal': 'Senegal',
  'serbia': 'Serbia',
  'south_korea': 'Corea del Sur',
  'south_africa': 'Sudáfrica',
  'spain': 'España',
  'sweden': 'Suecia',
  'switzerland': 'Suiza',
  'tunisia': 'Túnez',
  'turkey': 'Turquía',
  'ukraine': 'Ucrania',
  'uruguay': 'Uruguay',
  'usa': 'Estados Unidos',
  'uzbekistan': 'Uzbekistán',
  'wales': 'Gales',
};
