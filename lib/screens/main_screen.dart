import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart' show KiwiNovasTheme;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'calendar_screen.dart' show HomeScreen;
import 'analysis_screen.dart';
import 'profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;

  static const _screens = [
    HomeScreen(),
    AnalysisScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = KiwiNovasTheme.of(context).colors;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: colors.surface,
        indicatorColor: colors.primary.withAlpha(30),
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: colors.placeholder),
            selectedIcon: Icon(Icons.home, color: colors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined, color: colors.placeholder),
            selectedIcon: Icon(Icons.bar_chart, color: colors.primary),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: colors.placeholder),
            selectedIcon: Icon(Icons.person, color: colors.primary),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
