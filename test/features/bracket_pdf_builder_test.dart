import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_cup_bracket/src/data/sample_data.dart';
import 'package:world_cup_bracket/src/domain/bracket_rules.dart';
import 'package:world_cup_bracket/src/domain/models.dart';
import 'package:world_cup_bracket/src/features/bracket_pdf/bracket_pdf_builder.dart';

void main() {
  test('builds a personalized wallchart bracket PDF document', () async {
    final bytes = await buildBracketPdf(
      bracket: _completeBracket(),
      countries: sampleCountries,
      username: 'Ricky2026',
      locale: const Locale('en'),
      flagBytesByCountryId: {'brazil': _onePixelPng},
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('builds a Spanish bracket PDF document', () async {
    final bytes = await buildBracketPdf(
      bracket: _completeBracket(),
      countries: sampleCountries,
      username: 'Ricky2026',
      locale: const Locale('es'),
      flagBytesByCountryId: {'brazil': _onePixelPng},
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });
}

final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGP4z8AAAAMBAQDJ/pLvAAAAAElFTkSuQmCC',
);

Bracket _completeBracket() {
  return Bracket.empty('user').copyWith(
    groupPicks: [
      for (final groupId in BracketRules.groupIds)
        GroupPick(
          groupId: groupId,
          firstCountryId: BracketRules.groupCountryIds[groupId]![0],
          secondCountryId: BracketRules.groupCountryIds[groupId]![1],
          thirdCountryId: BracketRules.groupCountryIds[groupId]![2],
        ),
    ],
    bestThirdGroupIds: BracketRules.groupIds.take(8).toList(),
    knockoutPicks: [
      for (final slot in BracketRules.knockoutSlots())
        KnockoutPick(
          slotId: slot.id,
          stage: slot.stage,
          winnerCountryId: 'brazil',
        ),
    ],
  );
}
