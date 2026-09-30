import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../services/storage_service.dart';
import 'sub_page_scaffold.dart';

/// Namaz sonrası tesbihat: 33 Sübhanallah, 33 Elhamdülillah, 33 Allahu Ekber
/// (+1 ile 100). Sayaç cihazda saklanır.
class TesbihScreen extends StatefulWidget {
  const TesbihScreen({super.key});

  @override
  State<TesbihScreen> createState() => _TesbihScreenState();
}

class _Zikr {
  const _Zikr(this.text, this.meaning, this.target);

  final String text;
  final String meaning;
  final int target;
}

class _TesbihScreenState extends State<TesbihScreen> {
  static const _zikrs = [
    _Zikr('Sübhânallah', "Allah'ı tüm eksikliklerden tenzih ederim", 33),
    _Zikr('Elhamdülillâh', "Hamd Allah'a mahsustur", 33),
    _Zikr('Allâhu Ekber', 'Allah en büyüktür', 33),
  ];

  static int get _cycleLength =>
      _zikrs.fold(0, (sum, zikr) => sum + zikr.target);

  late final StorageService _storage;
  late int _total;

  @override
  void initState() {
    super.initState();
    _storage = context.read<StorageService>();
    _total = _storage.loadTesbihCount();
  }

  int get _positionInCycle => _total % _cycleLength;

  int get _zikrIndex {
    var remaining = _positionInCycle;
    for (var i = 0; i < _zikrs.length; i++) {
      if (remaining < _zikrs[i].target) return i;
      remaining -= _zikrs[i].target;
    }
    return 0;
  }

  int get _countInZikr {
    var remaining = _positionInCycle;
    for (var i = 0; i < _zikrIndex; i++) {
      remaining -= _zikrs[i].target;
    }
    return remaining;
  }

  int get _completedCycles => _total ~/ _cycleLength;

  void _increment() {
    setState(() => _total++);
    final finishedZikr = _countInZikr == 0;
    finishedZikr
        ? HapticFeedback.heavyImpact()
        : HapticFeedback.selectionClick();
    _storage.saveTesbihCount(_total);
  }

  void _reset() {
    setState(() => _total = 0);
    _storage.saveTesbihCount(0);
  }

  @override
  Widget build(BuildContext context) {
    final zikr = _zikrs[_zikrIndex];
    final count = _countInZikr;
    // Sayaç dairesi ekran yüksekliğine göre ölçeklenir (kaydırma yok).
    final ring = (MediaQuery.sizeOf(context).height * 0.34).clamp(150.0, 240.0);

    return SubPageScaffold(
      title: 'Tesbihat',
      actions: [
        IconButton(
          tooltip: 'Sıfırla',
          onPressed: _total == 0 ? null : _reset,
          icon: const Icon(Icons.restart_alt_rounded),
        ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < _zikrs.length; i++)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _zikrIndex ? 28 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: i == _zikrIndex
                          ? AppColors.gold
                          : AppColors.beige.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              zikr.text,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 6),
            Text(zikr.meaning, style: TextStyle(color: AppColors.beigeMuted)),
            const Spacer(),
            GestureDetector(
              onTap: _increment,
              child: SizedBox(
                width: ring,
                height: ring,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: count / zikr.target,
                        strokeWidth: 10,
                        backgroundColor: AppColors.anthracite,
                        valueColor:
                            const AlwaysStoppedAnimation(AppColors.gold),
                      ),
                    ),
                    Container(
                      width: ring - 40,
                      height: ring - 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.heroGradient,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$count',
                            style: TextStyle(
                              fontSize: ring * 0.26,
                              fontWeight: FontWeight.w300,
                              color: AppColors.beige,
                            ),
                          ),
                          Text(
                            '/ ${zikr.target}',
                            style: TextStyle(color: AppColors.beigeMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Saymak için dokunun',
              style: TextStyle(color: AppColors.beigeMuted, fontSize: 12),
            ),
            const Spacer(),
            Text(
              'Toplam: $_total   •   Tamamlanan tur: $_completedCycles',
              style: const TextStyle(color: AppColors.beige),
            ),
          ],
        ),
      ),
    );
  }
}
