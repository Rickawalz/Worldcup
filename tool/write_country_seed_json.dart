import 'dart:convert';
import 'dart:io';

import 'package:world_cup_bracket/src/data/sample_data.dart';

void main() {
  final countries = [
    for (final country in sampleCountries)
      {'id': country.id, ...country.toMap()},
  ];
  const encoder = JsonEncoder.withIndent('  ');
  stdout.writeln(encoder.convert(countries));
}
