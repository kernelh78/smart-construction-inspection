import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inspections_provider.dart';
import '../providers/sites_provider.dart';
import 'dashboard_screen.dart';
import 'sites/sites_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  final _screens = const [
    DashboardScreen(),
    _SitesTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: '대시보드'),
          NavigationDestination(icon: Icon(Icons.location_city), label: '현장'),
        ],
      ),
    );
  }
}

class _SitesTab extends StatelessWidget {
  const _SitesTab();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SitesProvider(),
      child: ChangeNotifierProvider(
        create: (_) => InspectionsProvider(),
        child: const SitesListScreen(),
      ),
    );
  }
}
