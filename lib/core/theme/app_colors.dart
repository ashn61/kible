import 'package:flutter/material.dart';

/// Kıble marka paleti.
abstract final class AppColors {
  /// Koyu mavi — ana arka plan.
  static const Color navy = Color(0xFF0B2D3B);

  /// Teal — vurgular ve aktif öğeler.
  static const Color teal = Color(0xFF0E5A5F);

  /// Altın — logo ve aktif vakit vurgusu.
  static const Color gold = Color(0xFFD4AF37);

  /// Açık bej — metinler.
  static const Color beige = Color(0xFFF7F5EF);

  /// Antrasit — kart arka planları.
  static const Color anthracite = Color(0xFF1F2937);

  static Color get beigeMuted => beige.withValues(alpha: 0.65);
  static Color get beigeFaint => beige.withValues(alpha: 0.12);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F3A4B), navy, Color(0xFF082230)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, Color(0xFF0A4248)],
  );
}
