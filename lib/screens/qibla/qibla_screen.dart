import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/qibla_provider.dart';
import '../../services/qibla_service.dart';
import '../../widgets/common.dart';
import 'widgets/compass_dial.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key, required this.isActive});

  /// Sekme görünür mü? Değilse pusula sensörü dinlenmez.
  final bool isActive;

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  bool _located = false;
  bool _wasAligned = false;

  /// Kıble yönüyle hizalı sayılmak için tolerans (derece).
  static const double _alignTolerance = 3;

  @override
  void initState() {
    super.initState();
    _locateOnce();
  }

  @override
  void didUpdateWidget(covariant QiblaScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _locateOnce();
  }

  void _locateOnce() {
    if (!widget.isActive || _located) return;
    _located = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<QiblaProvider>().locate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final qibla = context.watch<QiblaProvider>();
    // Web'de pusula sensörü desteklenmez.
    final compassStream =
        widget.isActive && !kIsWeb ? FlutterCompass.events : null;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kıble Yönü',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.beige,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Konumu yenile',
                  onPressed: qibla.isLoading ? null : qibla.locate,
                  icon: qibla.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location, color: AppColors.gold),
                ),
              ],
            ),
            if (qibla.message != null) ...[
              const SizedBox(height: 8),
              InfoBanner(text: qibla.message!, icon: Icons.location_off),
            ],
            const SizedBox(height: 12),
            // Pusula kalan alana göre boyutlanır; kaydırma yok.
            Expanded(
              child: widget.isActive && compassStream == null
                  ? _buildCompass(heading: null, sensorMissing: true)
                  : StreamBuilder<CompassEvent>(
                      stream: compassStream,
                      builder: (context, snapshot) => _buildCompass(
                        heading: snapshot.data?.heading,
                        sensorMissing: snapshot.hasError,
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            _InfoCard(qibla: qibla),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass({double? heading, required bool sensorMissing}) {
    final qibla = context.read<QiblaProvider>();
    final bearing = qibla.qiblaBearing;

    double? diff;
    if (heading != null) {
      diff = ((bearing - heading + 540) % 360) - 180; // -180..180
    }
    final aligned = diff != null && diff.abs() <= _alignTolerance;
    _hapticOnAlign(aligned);

    return Column(
      children: [
        Expanded(
          child: Center(
            child: CompassDial(
              heading: heading ?? 0,
              qiblaBearing: bearing,
              aligned: aligned,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          sensorMissing
              ? 'Pusula sensörü bulunamadı. Cihazınızın üst kısmını, kuzeye göre '
                  '${bearing.round()}° yönüne çevirin.'
              : heading == null
                  ? 'Pusula ayarlanıyor… Telefonunuzu 8 çizerek kalibre edin.'
                  : aligned
                      ? 'Kıble yönündesiniz'
                      : diff! > 0
                          ? 'Sağa doğru ${diff.abs().round()}° dönün'
                          : 'Sola doğru ${diff.abs().round()}° dönün',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: aligned ? 18 : 15,
            fontWeight: aligned ? FontWeight.w800 : FontWeight.w500,
            color: aligned ? AppColors.gold : AppColors.beigeMuted,
          ),
        ),
        if (heading != null) ...[
          const SizedBox(height: 4),
          Text(
            'Cihaz yönü ${((heading % 360 + 360) % 360).round()}° · '
            '${QiblaService.directionName(heading)}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.beigeMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ],
    );
  }

  void _hapticOnAlign(bool aligned) {
    if (aligned && !_wasAligned) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => HapticFeedback.mediumImpact());
    }
    _wasAligned = aligned;
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.qibla});

  final QiblaProvider qibla;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${qibla.qiblaBearing.round()}°',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w300,
                  color: AppColors.gold,
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    qibla.directionName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          _row(Icons.place_outlined, 'Koordinat', qibla.coordinates.formatted),
          _row(
            Icons.mosque_outlined,
            "Kâbe'ye uzaklık",
            '${qibla.distanceKm.round()} km',
          ),
          _row(
            Icons.gps_fixed,
            'Kaynak',
            qibla.isUsingFallback ? 'Trabzon (varsayılan)' : 'Cihaz konumu',
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.gold),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: AppColors.beigeMuted),
            ),
          ),
          const SizedBox(width: 12),
          // Değer sığmazsa kesilmek yerine küçülür.
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
