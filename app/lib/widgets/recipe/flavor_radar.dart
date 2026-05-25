import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:whipup/models/recipe.dart';

/// 맛 프로필 레이더 차트 위젯.
///
/// FlavorProfile의 5가지 맛(umami, sweet, sour, salty, spicy)을
/// 오각형 레이더 차트로 시각화한다.
///
/// 스타일: `docs/core/design_system.md §8.0`
class FlavorRadar extends StatelessWidget {
  const FlavorRadar({
    super.key,
    required this.flavorProfile,
    this.size = 180,
  });

  final FlavorProfile flavorProfile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final labels = ['감칠맛', '단맛', '신맛', '짠맛', '매운맛'];
    final values = [
      flavorProfile.umami / 5.0,
      flavorProfile.sweet / 5.0,
      flavorProfile.sour / 5.0,
      flavorProfile.salty / 5.0,
      flavorProfile.spicy / 5.0,
    ];

    return SizedBox(
      width: size + 60,
      height: size + 60,
      child: CustomPaint(
        painter: _RadarPainter(
          values: values,
          gridColor: cs.outlineVariant,
          fillColor: cs.primary.withValues(alpha: 0.15),
          strokeColor: cs.primary,
        ),
        child: _RadarLabels(
          labels: labels,
          values: [
            flavorProfile.umami,
            flavorProfile.sweet,
            flavorProfile.sour,
            flavorProfile.salty,
            flavorProfile.spicy,
          ],
          size: size + 60,
          textStyle: tt.labelSmall?.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 레이더 차트 페인터.
class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.values,
    required this.gridColor,
    required this.fillColor,
    required this.strokeColor,
  });

  final List<double> values;
  final Color gridColor;
  final Color fillColor;
  final Color strokeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 30;
    const sides = 5;
    const angleStep = (2 * math.pi) / sides;
    const startAngle = -math.pi / 2;

    // 배경 격자 그리기 (3단계)
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int level = 1; level <= 3; level++) {
      final r = radius * (level / 3);
      final path = Path();
      for (int i = 0; i < sides; i++) {
        final angle = startAngle + i * angleStep;
        final x = center.dx + r * math.cos(angle);
        final y = center.dy + r * math.sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    // 격자 축선 그리기
    final axisPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.3)
      ..strokeWidth = 0.8;
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + i * angleStep;
      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * math.cos(angle),
          center.dy + radius * math.sin(angle),
        ),
        axisPaint,
      );
    }

    // 데이터 폴리곤 그리기
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final dataPath = Path();
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + i * angleStep;
      final r = radius * values[i];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);

    // 데이터 포인트 점 그리기
    final dotPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < sides; i++) {
      final angle = startAngle + i * angleStep;
      final r = radius * values[i];
      canvas.drawCircle(
        Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        ),
        3.5,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      values != oldDelegate.values;
}

/// 레이더 차트 라벨 오버레이.
class _RadarLabels extends StatelessWidget {
  const _RadarLabels({
    required this.labels,
    required this.values,
    required this.size,
    this.textStyle,
  });

  final List<String> labels;
  final List<int> values;
  final double size;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final center = Offset(size / 2, size / 2);
    final radius = math.min(size, size) / 2 - 12;
    const sides = 5;
    const angleStep = (2 * math.pi) / sides;
    const startAngle = -math.pi / 2;

    return Stack(
      children: [
        for (int i = 0; i < sides; i++)
          Positioned(
            left: center.dx + radius * math.cos(startAngle + i * angleStep) - 22,
            top: center.dy + radius * math.sin(startAngle + i * angleStep) - 16,
            child: SizedBox(
              width: 44,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    labels[i],
                    style: textStyle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                  Text(
                    '${values[i]}',
                    style: textStyle?.copyWith(fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
