import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sites_provider.dart';
import 'site_detail_screen.dart';
import 'site_create_screen.dart';
import 'sites_map_screen.dart';

class SitesListScreen extends StatefulWidget {
  const SitesListScreen({super.key});

  @override
  State<SitesListScreen> createState() => _SitesListScreenState();
}

class _SitesListScreenState extends State<SitesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  void _fetch() {
    final api = context.read<AuthProvider>().api;
    context.read<SitesProvider>().fetchSites(api);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active': return Colors.green;
      case 'completed': return Colors.blue;
      case 'suspended': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return '진행중';
      case 'completed': return '완료';
      case 'suspended': return '중단';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SitesProvider>();
    final isAdmin = context.watch<AuthProvider>().currentUser?.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('현장 관리'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: '지도 보기',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SitesMapScreen()),
            ),
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SiteCreateScreen()));
                _fetch();
              },
              backgroundColor: const Color(0xFF1565C0),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text('오류: ${provider.error}'))
              : provider.sites.isEmpty
                  ? const Center(child: Text('등록된 현장이 없습니다.'))
                  : RefreshIndicator(
                      onRefresh: () async => _fetch(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: provider.sites.length,
                        itemBuilder: (ctx, i) {
                          final site = provider.sites[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFF1565C0),
                                child: Icon(Icons.location_city, color: Colors.white),
                              ),
                              title: Text(site.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(site.address),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(site.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _statusLabel(site.status),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SiteDetailScreen(site: site)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
