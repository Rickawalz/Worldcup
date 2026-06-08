import 'dart:convert';
import 'dart:io';

import 'package:world_cup_bracket/src/data/fixture_seed_data.dart';

void main() {
  final fixtures = [
    for (final fixture in official2026FixtureSeed)
      {'id': fixture.id, ...fixture.toMap()},
  ];
  const encoder = JsonEncoder.withIndent('  ');
  // Keep this script stdout-only so other local seed tools can pipe it safely.
  stdout.writeln(encoder.convert(fixtures));
}
