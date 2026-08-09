import 'package:flutter/material.dart';

/// Renders a high-quality illustration or icon for a target muscle group.
class MuscleIllustration extends StatelessWidget {
  const MuscleIllustration({
    super.key,
    required this.muscleId,
    this.size = 48,
    this.borderRadius = 10,
    this.showBorder = true,
  });

  final String muscleId;
  final double size;
  final double borderRadius;
  final bool showBorder;

  String? _assetPathForMuscle(String id) {
    switch (id.toLowerCase()) {
      case 'chest':
        return 'assets/muscles/chest.png';
      case 'back':
        return 'assets/muscles/back.png';
      case 'shoulders':
        return 'assets/muscles/shoulders.png';
      default:
        return null;
    }
  }

  IconData _iconForMuscle(String id) {
    switch (id.toLowerCase()) {
      case 'chest':
        return Icons.fitness_center;
      case 'back':
        return Icons.shield_outlined;
      case 'shoulders':
        return Icons.accessibility_new_rounded;
      case 'biceps':
      case 'triceps':
        return Icons.sports_gymnastics;
      case 'quadriceps':
      case 'hamstrings':
        return Icons.directions_run_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  Color _accentColorForMuscle(String id) {
    switch (id.toLowerCase()) {
      case 'chest':
        return const Color(0xFF00E5FF); // Electric Cyan
      case 'back':
        return const Color(0xFFFF9100); // Deep Orange
      case 'shoulders':
        return const Color(0xFF7C4DFF); // Deep Purple / Neon
      case 'biceps':
        return const Color(0xFFFF5252); // Coral Red
      case 'triceps':
        return const Color(0xFFFFD740); // Amber
      case 'quadriceps':
        return const Color(0xFF69F0AE); // Mint Green
      case 'hamstrings':
        return const Color(0xFF40C4FF); // Light Blue
      default:
        return const Color(0xFF00E5FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetPathForMuscle(muscleId);
    final accentColor = _accentColorForMuscle(muscleId);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(180),
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(color: accentColor.withAlpha(100), width: 1.5)
            : null,
        boxShadow: showBorder
            ? [
                BoxShadow(
                  color: accentColor.withAlpha(30),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: assetPath != null
          ? Image.asset(
              assetPath,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _FallbackIcon(
                icon: _iconForMuscle(muscleId),
                accentColor: accentColor,
                size: size,
              ),
            )
          : _FallbackIcon(
              icon: _iconForMuscle(muscleId),
              accentColor: accentColor,
              size: size,
            ),
    );
  }
}

class _FallbackIcon extends StatelessWidget {
  const _FallbackIcon({
    required this.icon,
    required this.accentColor,
    required this.size,
  });

  final IconData icon;
  final Color accentColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(icon, color: accentColor, size: size * 0.55),
    );
  }
}
