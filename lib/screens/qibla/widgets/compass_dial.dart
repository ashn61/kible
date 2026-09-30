import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Pusula kadranı. Kadran, cihazın yönüne göre döner; Kâbe işareti kadran
/// üzerinde kıble açısında durur. Üstteki sabit gösterge telefonun baktığı
/// yönü gösterir — Kâbe işareti göstergeye geldiğinde kıble yönü bulunmuştur.
class CompassDial extends StatefulWidget {
  const CompassDial({
    super.key,
    required this.heading,
    required this.qiblaBearing,
    required this.aligned,
  });

  /// Cihazın baktığı yön (kuzeye göre derece).
  final double heading;
  final double qiblaBearing;
  final bool aligned;

  @override
  State<CompassDial> createState() => _CompassDialState();
}

class _CompassDialState extends State<CompassDial> {
  /// Kümülatif dönüş (tur). 359° → 1° geçişinde kadranın ters yönde tam tur
  /// atmaması için her güncellemede en kısa yol eklenir.
  late double _turns = -widget.heading / 360;

  @override
  void didUpdateWidget(covariant CompassDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    final delta = ((widget.heading - oldWidget.heading + 540) % 360) - 180;
    _turns -= delta / 360;
  }

  @override
  Widget build(BuildContext context) {
    final aligned = widget.aligned;
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = [
          constraints.maxWidth,
          constraints.maxHeight - 24,
          320.0,
        ].reduce(math.min).clamp(120.0, 320.0);
        return SizedBox(
          width: size,
          height: size + 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 24,
                child: AnimatedRotation(
                  turns: _turns,
                  duration: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: size,
                    height: size,
                    child: CustomPaint(
                      painter: _DialPainter(qiblaBearing: widget.qiblaBearing),
                      child: _KaabaMarker(
                        bearing: widget.qiblaBearing,
                        radius: size / 2 - 44,
                        aligned: aligned,
                      ),
                    ),
                  ),
                ),
              ),
              // Sabit gösterge (telefonun üst kısmı).
              Positioned(
                top: 0,
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 44,
                  color: aligned ? AppColors.gold : AppColors.beige,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KaabaMarker extends StatelessWidget {
  const _KaabaMarker({
    required this.bearing,
    required this.radius,
    required this.aligned,
  });

  final double bearing;
  final double radius;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final angle = bearing * math.pi / 180;
    return Center(
      child: Transform.translate(
        offset: Offset(radius * math.sin(angle), -radius * math.cos(angle)),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: aligned ? AppColors.gold : AppColors.anthracite,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 2),
            boxShadow: aligned
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.6),
                      blurRadius: 20,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            Icons.mosque,
            size: 22,
            color: aligned ? AppColors.navy : AppColors.gold,
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({required this.qiblaBearing});

  final double qiblaBearing;

  static const _cardinals = ['K', 'D', 'G', 'B'];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Zemin
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [AppColors.teal, AppColors.anthracite],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.gold.withValues(alpha: 0.6),
    );

    // Derece çizgileri
    final tickPaint = Paint()..strokeCap = StrokeCap.round;
    for (var deg = 0; deg < 360; deg += 5) {
      final major = deg % 30 == 0;
      tickPaint
        ..color =
            major ? AppColors.beige : AppColors.beige.withValues(alpha: 0.35)
        ..strokeWidth = major ? 2 : 1;
      final a = deg * math.pi / 180;
      final outer = radius - 8;
      final inner = outer - (major ? 12 : 6);
      canvas.drawLine(
        center + Offset(math.sin(a) * inner, -math.cos(a) * inner),
        center + Offset(math.sin(a) * outer, -math.cos(a) * outer),
        tickPaint,
      );
    }

    // Ana yönler
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final r = radius - 36;
      final tp = TextPainter(
        text: TextSpan(
          text: _cardinals[i],
          style: TextStyle(
            color: i == 0 ? const Color(0xFFE57373) : AppColors.beige,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(
        center.dx + math.sin(a) * r,
        center.dy - math.cos(a) * r,
      );
      canvas.rotate(a);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Merkezden kıbleye çizgi
    final q = qiblaBearing * math.pi / 180;
    final lineEnd = radius - 64;
    canvas.drawLine(
      center,
      center + Offset(math.sin(q) * lineEnd, -math.cos(q) * lineEnd),
      Paint()
        ..color = AppColors.gold
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(center, 7, Paint()..color = AppColors.gold);
    canvas.drawCircle(center, 3, Paint()..color = AppColors.navy);
  }

  @override
  bool shouldRepaint(covariant _DialPainter oldDelegate) =>
      oldDelegate.qiblaBearing != qiblaBearing;
}
