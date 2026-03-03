import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BurstHeroCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String subtitle;

  const BurstHeroCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFDDEAFF),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFB4CDED), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BurstPainter(
                  background: const Color(0xFFDDEAFF),
                  rayA: const Color(0xFFCFE0F6),
                  rayB: const Color(0xFFE6F0FF),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTheme.heading3.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 14),
                _LayeredBigNumber(value: value),
                const SizedBox(height: 2),
                Text(unit, style: AppTheme.heading2.copyWith(fontSize: 34)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFB4CDED)),
                  ),
                  child: Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LayeredBigNumber extends StatelessWidget {
  final String value;

  const _LayeredBigNumber({required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 5; i > 0; i--)
            Positioned(
              top: i * 3,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  color: i.isEven
                      ? const Color(0xFF5EA8FF)
                      : AppTheme.textPrimaryColor,
                  height: 1,
                  letterSpacing: -2,
                ),
              ),
            ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 80,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
              letterSpacing: -2,
            ),
          ),
        ],
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  final Color background;
  final Color rayA;
  final Color rayB;

  _BurstPainter({
    required this.background,
    required this.rayA,
    required this.rayB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bg = Paint()..color = background;
    canvas.drawRect(rect, bg);

    final center = Offset(size.width * 0.5, size.height * 0.34);
    final radius = math.max(size.width, size.height) * 1.2;

    for (int i = 0; i < 12; i++) {
      final startAngle = (i * 30) * math.pi / 180;
      final sweep = 18 * math.pi / 180;
      final paint = Paint()..color = i.isEven ? rayA : rayB;

      final path = Path()..moveTo(center.dx, center.dy);
      path.lineTo(
        center.dx + radius * math.cos(startAngle),
        center.dy + radius * math.sin(startAngle),
      );
      path.lineTo(
        center.dx + radius * math.cos(startAngle + sweep),
        center.dy + radius * math.sin(startAngle + sweep),
      );
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) {
    return oldDelegate.background != background ||
        oldDelegate.rayA != rayA ||
        oldDelegate.rayB != rayB;
  }
}
