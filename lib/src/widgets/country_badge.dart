import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../localization/country_names.dart';
import 'country_flags.dart';

class CountryBadge extends StatelessWidget {
  const CountryBadge({
    required this.country,
    this.compact = false,
    this.abbreviationOnly = false,
    super.key,
  });

  final Country country;
  final bool compact;
  final bool abbreviationOnly;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final name = countryDisplayName(context, country);
    final emoji = flagEmoji(country);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: Image.network(
            country.flagUrl,
            width: compact ? 24 : 32,
            height: compact ? 16 : 22,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => Container(
                  width: compact ? 24 : 32,
                  height: compact ? 16 : 22,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Text(
                    emoji ?? country.abbreviation.characters.take(2).toString(),
                    style:
                        emoji == null
                            ? textTheme.labelSmall
                            : textTheme.titleMedium,
                  ),
                ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            abbreviationOnly
                ? country.abbreviation
                : compact
                ? name
                : '$name (${country.abbreviation})',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
