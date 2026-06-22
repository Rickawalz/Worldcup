import 'package:flutter/material.dart';

class DashboardColors {
  const DashboardColors._();

  static const navy = Color(0xFF061927);
  static const midnight = Color(0xFF031018);
  static const pitch = Color(0xFF0B5D3B);
  static const emerald = Color(0xFF19A66A);
  static const gold = Color(0xFFF5C542);
  static const sky = Color(0xFF51C8FF);
  static const card = Color(0xE6142533);
  static const cardStrong = Color(0xF01A3447);
}

ThemeData buildDashboardTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: DashboardColors.emerald,
    brightness: Brightness.dark,
  ).copyWith(
    primary: DashboardColors.emerald,
    secondary: DashboardColors.gold,
    tertiary: DashboardColors.sky,
    surface: DashboardColors.card,
    surfaceContainerHighest: DashboardColors.cardStrong,
    onSurface: Colors.white,
    onSurfaceVariant: const Color(0xFFC4D3DD),
  );

  final base = ThemeData(
    colorScheme: colorScheme,
    brightness: Brightness.dark,
    useMaterial3: true,
  );

  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xF0061927),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: DashboardColors.card,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0x1FFFFFFF)),
      ),
      margin: EdgeInsets.zero,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: DashboardColors.emerald,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Color(0x66FFFFFF)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: DashboardColors.gold),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0x66142533),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0x33FFFFFF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: DashboardColors.gold),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xF0061927),
      indicatorColor: DashboardColors.emerald.withValues(alpha: 0.24),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          color:
              states.contains(WidgetState.selected)
                  ? DashboardColors.gold
                  : const Color(0xFFC4D3DD),
          fontSize: 11,
          fontWeight:
              states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color:
              states.contains(WidgetState.selected)
                  ? DashboardColors.gold
                  : const Color(0xFFC4D3DD),
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Color(0xE6061927),
      selectedIconTheme: IconThemeData(color: DashboardColors.gold),
      selectedLabelTextStyle: TextStyle(
        color: DashboardColors.gold,
        fontWeight: FontWeight.w700,
      ),
      unselectedIconTheme: IconThemeData(color: Color(0xFFC4D3DD)),
      unselectedLabelTextStyle: TextStyle(color: Color(0xFFC4D3DD)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? DashboardColors.emerald.withValues(alpha: 0.26)
                  : const Color(0x66142533),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? DashboardColors.gold
                  : Colors.white,
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: DashboardColors.emerald.withValues(alpha: 0.18),
      selectedColor: DashboardColors.gold.withValues(alpha: 0.22),
      labelStyle: const TextStyle(color: Colors.white),
      side: const BorderSide(color: Color(0x22FFFFFF)),
    ),
  );
}

class DashboardBackground extends StatelessWidget {
  const DashboardBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DashboardColors.midnight,
            DashboardColors.navy,
            Color(0xFF06351F),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: -80,
            right: -60,
            child: _Glow(size: 220, color: DashboardColors.emerald),
          ),
          const Positioned(
            bottom: -100,
            left: -80,
            child: _Glow(size: 260, color: DashboardColors.gold),
          ),
          Positioned.fill(child: CustomPaint(painter: _FieldLinePainter())),
          child,
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.stats = const [],
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<DashboardStat> stats;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        DashboardHeader(
          title: title,
          subtitle: subtitle,
          icon: icon,
          stats: stats,
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    );
  }
}

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.stats = const [],
    this.compact = false,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<DashboardStat> stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 20 : 30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF01A3447), Color(0xD90B5D3B)],
        ),
        border: Border.all(color: const Color(0x29FFFFFF)),
      ),
      child: Stack(
        children: [
          if (!compact)
            Positioned(
              right: -24,
              top: -24,
              child: Icon(
                Icons.sports_soccer,
                color: Colors.white.withValues(alpha: 0.08),
                size: 150,
              ),
            ),
          Padding(
            padding: EdgeInsets.all(compact ? 12 : 22),
            child:
                compact
                    ? _buildCompactContent(theme)
                    : _buildFullContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactContent(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: DashboardColors.gold.withValues(alpha: 0.2),
          foregroundColor: DashboardColors.gold,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (stats.isNotEmpty) ...[
          const SizedBox(width: 8),
          for (final stat in stats) DashboardStatChip(stat: stat, compact: true),
        ],
      ],
    );
  }

  Widget _buildFullContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: DashboardColors.gold.withValues(alpha: 0.2),
          foregroundColor: DashboardColors.gold,
          child: Icon(icon),
        ),
        const SizedBox(height: 14),
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final stat in stats) DashboardStatChip(stat: stat),
            ],
          ),
        ],
      ],
    );
  }
}

class DashboardSectionCard extends StatelessWidget {
  const DashboardSectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: padding, child: child));
  }
}

class DashboardStat {
  const DashboardStat({
    required this.label,
    required this.value,
    this.icon,
    this.color = DashboardColors.gold,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color color;
}

class DashboardStatChip extends StatelessWidget {
  const DashboardStatChip({required this.stat, this.compact = false, super.key});

  final DashboardStat stat;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stat.color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (stat.icon != null) ...[
            Icon(stat.icon, size: compact ? 14 : 18, color: stat.color),
            SizedBox(width: compact ? 4 : 8),
          ],
          Text(
            stat.value,
            style: TextStyle(
              color: stat.color,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : null,
            ),
          ),
          SizedBox(width: compact ? 4 : 6),
          Text(stat.label, style: TextStyle(fontSize: compact ? 12 : null)),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.14),
        ),
      ),
    );
  }
}

class _FieldLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.035)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;

    final centerY = size.height * 0.45;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), paint);
    canvas.drawCircle(Offset(size.width * 0.5, centerY), 82, paint);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.08, centerY - 90, 120, 180),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.92 - 120, centerY - 90, 120, 180),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
