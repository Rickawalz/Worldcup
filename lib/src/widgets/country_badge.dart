import 'package:flutter/material.dart';

import '../domain/models.dart';

class CountryBadge extends StatelessWidget {
  const CountryBadge({required this.country, this.compact = false, super.key});

  final Country country;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
                    country.abbreviation.characters.take(2).toString(),
                    style: textTheme.labelSmall,
                  ),
                ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            compact
                ? country.name
                : '${country.name} (${country.abbreviation})',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
