import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../domain/bracket_rules.dart';
import '../../domain/models.dart';
import '../../localization/app_strings.dart';
import '../../localization/country_names.dart';

Future<Uint8List> buildBracketPdf({
  required Bracket bracket,
  required List<Country> countries,
  required String username,
  required Locale locale,
  Map<String, Uint8List>? flagBytesByCountryId,
}) async {
  final flagBytes = flagBytesByCountryId ?? await _fetchFlagBytes(countries);
  final builder = _BracketPdfBuilder(
    bracket: bracket,
    countries: countries,
    username: username,
    locale: locale,
    flagBytesByCountryId: flagBytes,
  );
  return builder.build();
}

Future<Map<String, Uint8List>> _fetchFlagBytes(List<Country> countries) async {
  final flags = <String, Uint8List>{};
  await Future.wait([
    for (final country in countries)
      () async {
        final url = Uri.tryParse(country.flagUrl);
        if (url == null) {
          return;
        }
        try {
          final response = await http.get(url);
          if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
            flags[country.id] = response.bodyBytes;
          }
        } catch (_) {
          // Flag images are decorative; country abbreviations remain available.
        }
      }(),
  ]);
  return flags;
}

class _BracketPdfBuilder {
  _BracketPdfBuilder({
    required this.bracket,
    required List<Country> countries,
    required this.username,
    required this.locale,
    required this.flagBytesByCountryId,
  }) : strings = AppStrings(locale),
       countryById = {for (final country in countries) country.id: country};

  final Bracket bracket;
  final Map<String, Country> countryById;
  final String username;
  final Locale locale;
  final Map<String, Uint8List> flagBytesByCountryId;
  final AppStrings strings;

  Future<Uint8List> build() async {
    final document = pw.Document(title: strings.pdfBracketTitle(username));
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.all(14),
        build: (_) => _wallchartPage(),
      ),
    );
    return document.save();
  }

  pw.Widget _wallchartPage() {
    final roundOf32 = BracketRules.roundOf32Slots;
    final roundOf16 =
        BracketRules.laterRoundSlots
            .where((slot) => slot.stage == TournamentStage.roundOf16)
            .toList();
    final quarterfinals =
        BracketRules.laterRoundSlots
            .where((slot) => slot.stage == TournamentStage.quarterfinal)
            .toList();
    final semifinals =
        BracketRules.laterRoundSlots
            .where((slot) => slot.stage == TournamentStage.semifinal)
            .toList();
    final finalSlot = BracketRules.laterRoundSlots.firstWhere(
      (slot) => slot.stage == TournamentStage.finalMatch,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        gradient: const pw.LinearGradient(
          begin: pw.Alignment.topCenter,
          end: pw.Alignment.bottomCenter,
          colors: [
            PdfColor.fromInt(0xFF102A3D),
            PdfColor.fromInt(0xFF0A4A32),
            PdfColor.fromInt(0xFF06131D),
          ],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Stack(
        children: [
          pw.Positioned.fill(child: _pdfFieldBackdrop()),
          pw.Positioned(
            right: 2,
            bottom: 0,
            child: pw.Text(
              _pdfSafe(strings.pdfAppCredit),
              style: const pw.TextStyle(fontSize: 6, color: PdfColors.white),
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _pdfWallchartTitle(),
              pw.SizedBox(height: 7),
              pw.Expanded(
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _stageColumn(
                      strings.roundOf32,
                      roundOf32.take(8).toList(),
                      const PdfColor.fromInt(0xFF4057A8),
                    ),
                    _stageColumn(
                      strings.roundOf16,
                      roundOf16.take(4).toList(),
                      const PdfColor.fromInt(0xFF61B34A),
                    ),
                    _stageColumn(
                      strings.quarterfinals,
                      quarterfinals.take(2).toList(),
                      const PdfColor.fromInt(0xFFE05D3F),
                    ),
                    _stageColumn(
                      strings.semifinals,
                      semifinals.take(1).toList(),
                      const PdfColor.fromInt(0xFF6F6681),
                    ),
                    _centerPanel(finalSlot),
                    _stageColumn(
                      strings.semifinals,
                      semifinals.skip(1).toList(),
                      const PdfColor.fromInt(0xFF6F6681),
                    ),
                    _stageColumn(
                      strings.quarterfinals,
                      quarterfinals.skip(2).toList(),
                      const PdfColor.fromInt(0xFFE05D3F),
                    ),
                    _stageColumn(
                      strings.roundOf16,
                      roundOf16.skip(4).toList(),
                      const PdfColor.fromInt(0xFF61B34A),
                    ),
                    _stageColumn(
                      strings.roundOf32,
                      roundOf32.skip(8).toList(),
                      const PdfColor.fromInt(0xFF4057A8),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              _compactGroupPicksStrip(),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfFieldBackdrop() {
    return pw.CustomPaint(
      painter: (PdfGraphics canvas, PdfPoint size) {
        canvas
          ..setColor(const PdfColor.fromInt(0x22FFFFFF))
          ..setLineWidth(0.6);
        final centerY = size.y * 0.58;
        canvas
          ..drawLine(0, centerY, size.x, centerY)
          ..strokePath()
          ..drawEllipse(size.x / 2 - 45, centerY - 45, 90, 90)
          ..strokePath();
        for (var i = 0; i < 6; i++) {
          final y = size.y * (0.2 + i * 0.08);
          canvas
            ..drawLine(0, y, size.x, y)
            ..strokePath();
        }
      },
    );
  }

  pw.Widget _pdfWallchartTitle() {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 10),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber600,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        _pdfSafe(strings.pdfBracketTitle(username)),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 20,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blueGrey900,
        ),
      ),
    );
  }

  pw.Widget _centerPanel(BracketSlot finalSlot) {
    final champion = _countryLabel(bracket.championCountryId);
    return pw.Expanded(
      flex: 2,
      child: pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text(
              'TROPHY',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber300,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Container(
              width: 54,
              height: 54,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: PdfColors.amber600,
                shape: pw.BoxShape.circle,
                border: pw.Border.all(color: PdfColors.amber100, width: 1.2),
              ),
              child: pw.Text(
                'CUP',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              _pdfSafe(strings.finalRound.toUpperCase()),
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber300,
              ),
            ),
            pw.SizedBox(height: 5),
            _matchBox(finalSlot, PdfColors.amber600, isCenterpiece: true),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.amber100,
                borderRadius: pw.BorderRadius.circular(7),
                border: pw.Border.all(color: PdfColors.amber600, width: 1),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    _pdfSafe(strings.winner.toUpperCase()),
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  _countryRow(champion, 8, isWinner: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _compactGroupPicksStrip() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xAA06131D),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.white, width: 0.25),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 72,
            child: pw.Text(
              _pdfSafe(strings.pdfGroupPicks),
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.amber300,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final groupId in BracketRules.groupIds)
                  _compactGroupCard(groupId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _compactGroupCard(String groupId) {
    return pw.Container(
      width: 55,
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(3),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _pdfSafe(strings.group(groupId)),
            style: pw.TextStyle(
              fontSize: 5.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey900,
            ),
          ),
          _compactGroupPickLine('1', _groupCountryId(groupId, 1)),
          _compactGroupPickLine('2', _groupCountryId(groupId, 2)),
          _compactGroupPickLine(
            '3',
            _groupCountryId(groupId, 3),
            suffix: bracket.bestThirdGroupIds.contains(groupId) ? '*' : '',
          ),
        ],
      ),
    );
  }

  pw.Widget _compactGroupPickLine(
    String place,
    String? countryId, {
    String suffix = '',
  }) {
    return pw.Row(
      children: [
        pw.Text('$place ', style: const pw.TextStyle(fontSize: 4.6)),
        _pdfFlagBox(countryId, width: 7, height: 4.8, fontSize: 3.2),
        pw.SizedBox(width: 1.5),
        pw.Expanded(
          child: pw.Text(
            '${_countryShort(countryId)}$suffix',
            maxLines: 1,
            style: const pw.TextStyle(fontSize: 4.6),
          ),
        ),
      ],
    );
  }

  pw.Widget _stageColumn(
    String title,
    List<BracketSlot> slots,
    PdfColor color,
  ) {
    return pw.Expanded(
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 2),
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              _pdfSafe(title.toUpperCase()),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 5.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          for (final slot in slots)
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(
                vertical:
                    slot.stage == TournamentStage.roundOf32
                        ? 1.6
                        : slot.stage == TournamentStage.roundOf16
                        ? 5.0
                        : 13.0,
              ),
              child: _matchBox(slot, color),
            ),
        ],
      ),
    );
  }

  pw.Widget _matchBox(
    BracketSlot slot,
    PdfColor color, {
    bool isCenterpiece = false,
  }) {
    final winner = _winnerCountryId(slot);
    final participants = _participantCountryIds(slot);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        color: color.shade(0.15),
        border: pw.Border.all(color: color, width: 0.7),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            _slotLabel(slot),
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: isCenterpiece ? 5.8 : 4.4,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 2),
          for (final countryId in participants)
            _wallchartTeamLine(countryId, isCenterpiece ? 6 : 4.6),
          pw.SizedBox(height: 2),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              _pdfSafe('${strings.winner}: ${_countryShort(winner)}'),
              maxLines: 1,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: isCenterpiece ? 6 : 4.7,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _wallchartTeamLine(String? countryId, double fontSize) {
    final label = _countryShort(countryId);
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 1.4),
      padding: const pw.EdgeInsets.symmetric(vertical: 1.6, horizontal: 2),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(2.5),
      ),
      child: pw.Row(
        children: [
          _pdfFlagBox(
            countryId,
            width: fontSize + 4,
            height: fontSize + 1.5,
            fontSize: fontSize - 1.6,
          ),
          pw.SizedBox(width: 2),
          pw.Expanded(
            child: pw.Text(
              label,
              maxLines: 1,
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _groupCountryId(String groupId, int place) {
    final pick =
        bracket.groupPicks
            .where((groupPick) => groupPick.groupId == groupId)
            .firstOrNull;
    if (pick == null) {
      return null;
    }
    return switch (place) {
      1 => pick.firstCountryId,
      2 => pick.secondCountryId,
      3 => pick.thirdCountryId,
      _ => null,
    };
  }

  String? _winnerCountryId(BracketSlot slot) {
    final winnerCountryId =
        bracket.knockoutPicks
            .where((pick) => pick.slotId == slot.id)
            .map((pick) => pick.winnerCountryId)
            .firstOrNull;
    return winnerCountryId;
  }

  List<String?> _participantCountryIds(BracketSlot slot) {
    final participantIds = BracketRules.resolveSlotParticipantIds(
      bracket,
      slot,
    );
    if (participantIds.length == 2) {
      return [participantIds[0], participantIds[1]];
    }
    return [
      _sourceCountryId(slot.sourceA, slot),
      _sourceCountryId(slot.sourceB, slot),
    ];
  }

  String? _sourceCountryId(String source, BracketSlot slot) {
    var effectiveSource = source;
    if (source.startsWith('3rd ')) {
      effectiveSource =
          BracketRules.resolvedThirdPlaceSource(bracket, slot) ?? source;
    }
    return BracketRules.resolveSourceCountryId(bracket, effectiveSource);
  }

  String _countryLabel(String? countryId) {
    if (countryId == null || countryId.isEmpty) {
      return _pdfSafe(strings.pdfTbd);
    }
    final country = countryById[countryId];
    if (country == null) {
      return countryId;
    }
    final name = _pdfSafe(countryDisplayNameForLocale(locale, country));
    return '${country.abbreviation} $name';
  }

  String _countryShort(String? countryId) {
    if (countryId == null || countryId.isEmpty) {
      return _pdfSafe(strings.pdfTbd);
    }
    final country = countryById[countryId];
    if (country == null) {
      return _pdfSafe(countryId);
    }
    return country.abbreviation;
  }

  String _slotLabel(BracketSlot slot) {
    final matchNumber = RegExp(r'^Match\s+(\d+)$').firstMatch(slot.label);
    if (matchNumber != null) {
      return _pdfSafe(
        strings.isSpanish ? 'Partido ${matchNumber.group(1)!}' : slot.label,
      );
    }
    return _pdfSafe(slot.label == 'Final' ? strings.finalRound : slot.label);
  }

  pw.Widget _countryRow(
    String? countryId,
    double fontSize, {
    bool isWinner = false,
  }) {
    final country = countryId == null ? null : countryById[countryId];
    final label = _countryLabel(countryId);
    final flagBytes = country == null ? null : flagBytesByCountryId[country.id];
    return pw.Container(
      margin: const pw.EdgeInsets.symmetric(vertical: 1),
      padding:
          isWinner
              ? const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 3)
              : pw.EdgeInsets.zero,
      decoration:
          isWinner
              ? pw.BoxDecoration(
                color: PdfColors.green100,
                borderRadius: pw.BorderRadius.circular(3),
              )
              : null,
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (flagBytes != null)
            pw.Container(
              width: fontSize + 8,
              height: fontSize + 4,
              margin: const pw.EdgeInsets.only(right: 3),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.3),
              ),
              child: pw.Image(pw.MemoryImage(flagBytes), fit: pw.BoxFit.cover),
            )
          else
            pw.Container(
              width: fontSize + 8,
              height: fontSize + 4,
              margin: const pw.EdgeInsets.only(right: 3),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey100,
                border: pw.Border.all(color: PdfColors.grey300, width: 0.3),
              ),
              child: pw.Text(
                country?.abbreviation.characters.take(2).toString() ?? '--',
                style: pw.TextStyle(fontSize: fontSize - 1),
              ),
            ),
          pw.Expanded(
            child: pw.Text(
              label,
              maxLines: 1,
              style: pw.TextStyle(
                fontSize: fontSize,
                fontWeight:
                    isWinner ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isWinner ? PdfColors.green900 : PdfColors.blueGrey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfFlagBox(
    String? countryId, {
    required double width,
    required double height,
    required double fontSize,
  }) {
    final country = countryId == null ? null : countryById[countryId];
    final flagBytes = country == null ? null : flagBytesByCountryId[country.id];
    if (flagBytes != null) {
      return pw.Container(
        width: width,
        height: height,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400, width: 0.25),
        ),
        child: pw.Image(pw.MemoryImage(flagBytes), fit: pw.BoxFit.cover),
      );
    }
    return pw.Container(
      width: width,
      height: height,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: PdfColors.blueGrey100,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.25),
      ),
      child: pw.Text(
        country?.abbreviation.characters.take(2).toString() ?? '--',
        style: pw.TextStyle(fontSize: fontSize, color: PdfColors.blueGrey900),
      ),
    );
  }

  String _pdfSafe(String value) {
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'Á': 'A',
      'É': 'E',
      'Í': 'I',
      'Ó': 'O',
      'Ú': 'U',
      'ñ': 'n',
      'Ñ': 'N',
      'ç': 'c',
      'Ç': 'C',
      'ã': 'a',
      'õ': 'o',
      'ü': 'u',
      'Ü': 'U',
      'ï': 'i',
      'ô': 'o',
      '’': "'",
      'ʻ': "'",
      'ı': 'i',
      'ğ': 'g',
      'ş': 's',
      'º': 'o',
    };
    return value.split('').map((char) => replacements[char] ?? char).join();
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
