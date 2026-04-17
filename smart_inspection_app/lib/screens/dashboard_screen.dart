import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  void _fetch() {
    final api = context.read<AuthProvider>().api;
    context.read<DashboardProvider>().fetch(api);
  }

  @override
  Widget build(BuildContext context) {
    final dash = context.watch<DashboardProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('대시보드'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: dash.loading
          ? const Center(child: CircularProgressIndicator())
          : dash.error != null
              ? Center(child: Text('오류: ${dash.error}'))
              : RefreshIndicator(
                  onRefresh: () async => _fetch(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _UserCard(name: auth.currentUser?.name ?? '', role: auth.currentUser?.role ?? ''),
                      const SizedBox(height: 16),
                      if (dash.summary != null) _SummaryGrid(summary: dash.summary!),
                      const SizedBox(height: 16),
                      _UnresolvedDefectsCard(defects: dash.unresolvedDefects),
                    ],
                  ),
                ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String name;
  final String role;

  const _UserCard({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1565C0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(_roleLabel(role), style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin': return '관리자';
      case 'inspector': return '감리원';
      case 'site_manager': return '현장소장';
      case 'contractor': return '시공사';
      default: return role;
    }
  }
}

class _SummaryGrid extends StatelessWidget {
  final DashboardSummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    final items = [
      _SummaryItem('전체 현장', summary.totalSites.toString(), Icons.location_city, Colors.blue),
      _SummaryItem('활성 현장', summary.activeSites.toString(), Icons.check_circle, Colors.green),
      _SummaryItem('전체 점검', summary.totalInspections.toString(), Icons.assignment, Colors.orange),
      _SummaryItem('합격률', '${summary.passRate.toStringAsFixed(1)}%', Icons.thumb_up, Colors.teal),
      _SummaryItem('대기 점검', summary.pendingInspections.toString(), Icons.pending, Colors.purple),
      _SummaryItem('미결 결함', summary.unresolvedDefects.toString(), Icons.warning, Colors.red),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items.map((item) => _SummaryCard(item: item)).toList(),
    );
  }
}

class _SummaryItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _SummaryItem(this.label, this.value, this.icon, this.color);
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(item.icon, color: item.color, size: 28),
                Text(item.value,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: item.color)),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(item.label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnresolvedDefectsCard extends StatelessWidget {
  final List<UnresolvedDefect> defects;

  const _UnresolvedDefectsCard({required this.defects});

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical': return Colors.red;
      case 'major': return Colors.orange;
      default: return Colors.yellow.shade700;
    }
  }

  String _severityLabel(String severity) {
    switch (severity) {
      case 'critical': return '심각';
      case 'major': return '주요';
      default: return '경미';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('미결 결함 현황', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(),
            if (defects.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: Text('미결 결함이 없습니다.', style: TextStyle(color: Colors.grey))),
              )
            else
              ...defects.take(5).map((d) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _severityColor(d.severity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(_severityLabel(d.severity),
                          style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                    title: Text(d.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(d.siteName, style: const TextStyle(color: Colors.grey)),
                  )),
          ],
        ),
      ),
    );
  }
}
