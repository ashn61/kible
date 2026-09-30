import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Uygulama ikonunun canlı sürümü: ufuktan doğan güneş, hafifçe sallanan
/// hilal ve parlayıp sönen yıldızlar. Çizim `assets/icon/kible_icon.svg` ile aynı oranları kullanır.
class KibleLogo extends StatefulWidget {
  const KibleLogo({super.key, this.size = 36, this.animate = true});

  final double size;
  final bool animate;

  @override
  State<KibleLogo> createState() => _KibleLogoState();
}

class _KibleLogoState extends State<KibleLogo> with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // "Hareketi azalt" erişilebilirlik ayarına uy.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.animate && !reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
      if (!_twinkle.isAnimating) _twinkle.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0.5;
      _twinkle
        ..stop()
        ..value = 0.25;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final swing = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    return RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        painter: _KibleLogoPainter(swing, _twinkle),
      ),
    );
  }
}

class _KibleLogoPainter extends CustomPainter {
  _KibleLogoPainter(this.swing, this.twinkle)
      : super(repaint: Listenable.merge([swing, twinkle]));

  final Animation<double> swing;

  /// 0→1 döngü; her yıldız farklı fazda parlar/söner.
  final Animation<double> twinkle;

  /// Yıldızlar: merkez, boyut, faz (ikondaki konumlarla aynı).
  static const List<(Offset, double, double)> _stars = [
    (Offset(300, 190), 30, 0),
    (Offset(560, 330), 20, 0.45),
  ];

  /// Hilalin salınım genliği (radyan, ±).
  static const double _maxAngle = 12 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    // Tüm ölçüler 1024'lük ikon ızgarasında.
    final k = size.width / 1024;
    canvas.save();
    canvas.scale(k);

    const full = Rect.fromLTWH(0, 0, 1024, 1024);
    canvas.clipRRect(
      RRect.fromRectAndRadius(full, const Radius.circular(240)),
    );

    // Gökyüzü
    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0B2D3B),
            Color(0xFF113A4B),
            Color(0xFF4E5A3E),
            Color(0xFFC08F2E),
            Color(0xFFE0A93A),
          ],
          stops: [0, 0.45, 0.62, 0.72, 0.80],
        ).createShader(full),
    );
    // Ufuk parıltısı
    canvas.drawRect(
      full,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFF5C24A).withValues(alpha: 0.75),
            const Color(0x00F5C24A),
          ],
        ).createShader(
          Rect.fromCircle(center: const Offset(512, 700), radius: 380),
        ),
    );

    // Yıldızlar (dört köşeli, parlayıp söner)
    for (final (center, radius, phase) in _stars) {
      final t = (twinkle.value + phase) % 1.0;
      final glow = 0.5 - 0.5 * math.cos(t * 2 * math.pi); // 0..1..0
      _drawStar(
          canvas, center, radius * (0.75 + 0.25 * glow), 0.25 + 0.75 * glow);
    }

    // Güneş
    const sunCenter = Offset(512, 705);
    canvas.drawCircle(
      sunCenter,
      158,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6CF55), Color(0xFFE6AE2E)],
        ).createShader(Rect.fromCircle(center: sunCenter, radius: 158)),
    );

    // Tepe + altın kenar
    const hillCenter = Offset(512, 1520);
    final hillRect = Rect.fromCircle(center: hillCenter, radius: 830);
    canvas.drawCircle(
      hillCenter,
      830,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A4428), Color(0xFF2C2C22), Color(0xFF171D22)],
          stops: [0, 0.35, 1],
        ).createShader(const Rect.fromLTRB(0, 690, 1024, 1024)),
    );
    canvas.drawArc(
      hillRect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0xE6F2C14E),
    );

    // Hilal: üstteki bir noktaya asılıymış gibi sallanır.
    const pivot = Offset(740, 110);
    final angle = (swing.value * 2 - 1) * _maxAngle;
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    final crescent = Path.combine(
      PathOperation.difference,
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(740, 250), radius: 74)),
      Path()
        ..addOval(Rect.fromCircle(center: const Offset(772, 222), radius: 64)),
    );
    canvas.drawPath(
      crescent,
      Paint()
        ..color = const Color(0xFFD4AF37)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6),
    );
    canvas.restore();

    canvas.restore();
  }

  static void _drawStar(Canvas canvas, Offset c, double r, double opacity) {
    final inner = r * 0.22;
    final star = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx + inner, c.dy - inner, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx + inner, c.dy + inner, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx - inner, c.dy + inner, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx - inner, c.dy - inner, c.dx, c.dy - r)
      ..close();
    canvas.drawCircle(
      c,
      r * 0.9,
      Paint()
        ..color = const Color(0xFFF7F5EF).withValues(alpha: 0.18 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
    );
    canvas.drawPath(
      star,
      Paint()..color = const Color(0xFFF7F5EF).withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _KibleLogoPainter oldDelegate) =>
      oldDelegate.swing != swing || oldDelegate.twinkle != twinkle;
}
