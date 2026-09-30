import 'package:flutter/material.dart';

import '../widgets/common.dart';
import 'home/home_screen.dart';
import 'more/more_screen.dart';
import 'prayers/prayers_screen.dart';
import 'qibla/qibla_screen.dart';

/// Alt menülü ana iskelet. Sekmeler [IndexedStack] ile durumlarını korur.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _qiblaTab = 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: IndexedStack(
          index: _index,
          children: [
            const HomeScreen(),
            const PrayersScreen(),
            // Pusula sensörü yalnızca sekme açıkken dinlenir (pil tasarrufu).
            QiblaScreen(isActive: _index == _qiblaTab),
            const MoreScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            activeIcon: Icon(Icons.access_time_filled),
            label: 'Namazlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Kıble',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Daha Fazla',
          ),
        ],
      ),
    );
  }
}
