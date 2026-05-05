// lib/widgets/macro_ring.dart
import 'dart:math';
import 'package:flutter/material.dart';

class MacroRing extends StatelessWidget {
  final double calories, calorieTarget;
  final double protein, proteinTarget;
  final double carbs, carbsTarget;
  final double fat, fatTarget;

  const MacroRing({
    super.key,
    required this.calories,
    required this.calorieTarget,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(220, 220),
            painter: _RingPainter(
              rings: [
                // Outer - Calories (green)
                RingData(
                    value: (calories / calorieTarget).clamp(0, 1),
                    color: const Color(0xFF10B981),
                    trackColor: const Color(0xFF064E3B)),
                // Middle - Protein (purple)
                RingData(
                    value: (protein / proteinTarget).clamp(0, 1),
                    color: const Color(0xFF8B5CF6),
                    trackColor: const Color(0xFF2E1065)),
                // Inner - Carbs (amber)
                RingData(
                    value: (carbs / carbsTarget).clamp(0, 1),
                    color: const Color(0xFFF59E0B),
                    trackColor: const Color(0xFF451A03)),
              ],
            ),
          ),
          // Center text
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(calories.toInt().toString(),
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
            Text('/ ${calorieTarget.toInt()} kcal',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Text('remaining: ${(calorieTarget - calories).toInt()}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF10B981))),
          ]),
        ],
      ),
    );
  }
}

class RingData {
  final double value;
  final Color color, trackColor;
  RingData(
      {required this.value, required this.color, required this.trackColor});
}

class _RingPainter extends CustomPainter {
  final List<RingData> rings;
  _RingPainter({required this.rings});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const ringWidths = [16.0, 14.0, 12.0];
    const gaps = [0.0, 20.0, 38.0];

    for (int i = 0; i < rings.length; i++) {
      final ring = rings[i];
      final radius = (size.width / 2) - gaps[i] - ringWidths[i] / 2;
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Track
      canvas.drawArc(
          rect,
          0,
          2 * pi,
          false,
          Paint()
            ..color = ring.trackColor
            ..strokeWidth = ringWidths[i]
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);

      // Progress
      if (ring.value > 0) {
        canvas.drawArc(
            rect,
            -pi / 2,
            2 * pi * ring.value,
            false,
            Paint()
              ..color = ring.color
              ..strokeWidth = ringWidths[i]
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => true;
}
