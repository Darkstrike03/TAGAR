import 'dart:math' as math;

import 'package:flutter/material.dart';

class ChatBackground extends StatelessWidget {
  const ChatBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _TiledPatternPainter(),
        isComplex: true,
        willChange: false,
      ),
    );
  }
}

class _TiledPatternPainter extends CustomPainter {
  final double _tileW = 100;
  final double _tileH = 100;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5A8A3C).withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final cols = (size.width / _tileW).ceil() + 1;
    final rows = (size.height / _tileH).ceil() + 1;

    for (int row = 0; row < rows; row++) {
      final offsetX = row.isEven ? 0.0 : _tileW * 0.5;
      for (int col = 0; col < cols; col++) {
        final cx = col * _tileW + offsetX;
        final cy = row * _tileH + _tileH * 0.5;

        canvas.save();
        canvas.translate(cx, cy);

        final patternIdx = (row + col) % 3;
        if (patternIdx == 0) {
          _drawLeaf(canvas, paint);
        } else if (patternIdx == 1) {
          _drawSmallFlower(canvas, paint);
        } else {
          _drawTinyBranch(canvas, paint);
        }

        canvas.restore();
      }
    }
  }

  void _drawLeaf(Canvas canvas, Paint paint) {
    const s = 16.0;
    final path = Path();
    path.moveTo(0, -s * 0.6);
    path.cubicTo(
      s * 0.45, -s * 0.35,
      s * 0.45, s * 0.35,
      0, s * 0.6,
    );
    path.cubicTo(
      -s * 0.45, s * 0.35,
      -s * 0.45, -s * 0.35,
      0, -s * 0.6,
    );
    canvas.drawPath(path, paint);

    final stem = Path();
    stem.moveTo(0, s * 0.6);
    stem.lineTo(0, s * 0.85);
    canvas.drawPath(stem, paint);
  }

  void _drawSmallFlower(Canvas canvas, Paint paint) {
    const r = 6.0;
    for (int i = 0; i < 5; i++) {
      final angle = i * 2.0 * math.pi / 5 - math.pi / 2;
      final px = math.cos(angle) * r * 1.2;
      final py = math.sin(angle) * r * 1.2;
      final petal = Path()
        ..addOval(Rect.fromCenter(center: Offset(px, py), width: r, height: r));
      canvas.drawPath(petal, paint);
    }
    canvas.drawCircle(Offset.zero, r * 0.3, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
  }

  void _drawTinyBranch(Canvas canvas, Paint paint) {
    const l = 18.0;
    final branch = Path();
    branch.moveTo(-l * 0.3, l * 0.3);
    branch.cubicTo(0, 0, l * 0.1, -l * 0.2, l * 0.4, -l * 0.4);
    canvas.drawPath(branch, paint);

    final leaf1 = Path();
    leaf1.moveTo(l * 0.05, -l * 0.1);
    leaf1.cubicTo(
      l * 0.15, -l * 0.2,
      l * 0.25, -l * 0.1,
      l * 0.15, -l * 0.02,
    );
    leaf1.close();
    canvas.drawPath(leaf1, paint);

    final leaf2 = Path();
    leaf2.moveTo(l * 0.15, -l * 0.25);
    leaf2.cubicTo(
      l * 0.25, -l * 0.35,
      l * 0.35, -l * 0.2,
      l * 0.25, -l * 0.15,
    );
    leaf2.close();
    canvas.drawPath(leaf2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
