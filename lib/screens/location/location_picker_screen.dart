import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/location_models.dart';
import '../../providers/prayer_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';
import '../more/sub_page_scaffold.dart';

/// İl seçimi → ilçe seçimi. Seçilen ilçe kaydedilir ve vakitler yenilenir.
class LocationPickerScreen extends StatelessWidget {
  const LocationPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<ApiService>();
    return _RegionListPage(
      title: 'İl Seçin',
      loader: api.fetchCities,
      onSelected: (city) => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _RegionListPage(
          title: city.displayName,
          loader: () => api.fetchDistricts(city.id),
          onSelected: (district) => _select(context, city, district),
        ),
      )),
    );
  }

  static Future<void> _select(
    BuildContext context,
    Region city,
    Region district,
  ) async {
    final navigator = Navigator.of(context);
    final provider = context.read<PrayerProvider>();
    navigator.popUntil((route) => route.isFirst);
    await provider.changeLocation(SelectedLocation(
      districtId: district.id,
      districtName: district.displayName,
      cityName: city.displayName,
    ));
  }
}

class _RegionListPage extends StatefulWidget {
  const _RegionListPage({
    required this.title,
    required this.loader,
    required this.onSelected,
  });

  final String title;
  final Future<List<Region>> Function() loader;
  final ValueChanged<Region> onSelected;

  @override
  State<_RegionListPage> createState() => _RegionListPageState();
}

class _RegionListPageState extends State<_RegionListPage> {
  late Future<List<Region>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = widget.loader();
  }

  static String _normalize(String s) => s
      .replaceAll('İ', 'i')
      .replaceAll('I', 'ı')
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  @override
  Widget build(BuildContext context) {
    final selectedId = context.select<PrayerProvider, String>(
      (p) => p.location.districtId,
    );

    return SubPageScaffold(
      title: widget.title,
      body: FutureBuilder<List<Region>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: () => setState(() => _future = widget.loader()),
            );
          }

          final query = _normalize(_query);
          final items = snapshot.data!
              .where((r) => _normalize(r.name).contains(query))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(color: AppColors.beige),
                  decoration: InputDecoration(
                    hintText: 'Ara…',
                    prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                    filled: true,
                    fillColor: AppColors.anthracite,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final region = items[i];
                    final selected = region.id == selectedId;
                    return AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      onTap: () => widget.onSelected(region),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              region.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color:
                                    selected ? AppColors.gold : AppColors.beige,
                              ),
                            ),
                          ),
                          Icon(
                            selected ? Icons.check_circle : Icons.chevron_right,
                            color: selected
                                ? AppColors.gold
                                : AppColors.beigeMuted,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
