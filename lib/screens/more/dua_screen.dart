import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/duas.dart';
import '../../widgets/common.dart';
import 'sub_page_scaffold.dart';

class DuaScreen extends StatelessWidget {
  const DuaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageScaffold(
      title: 'Dualar',
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: duas.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, i) => _DuaCard(dua: duas[i]),
      ),
    );
  }
}

class _DuaCard extends StatelessWidget {
  const _DuaCard({required this.dua});

  final Dua dua;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dua.title,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (dua.source != null)
                Text(
                  dua.source!,
                  style: TextStyle(color: AppColors.beigeMuted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            dua.arabic,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontSize: 24,
              height: 1.9,
              color: AppColors.beige,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            dua.transliteration,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              height: 1.5,
              color: AppColors.beige,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            dua.meaning,
            style: TextStyle(color: AppColors.beigeMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
