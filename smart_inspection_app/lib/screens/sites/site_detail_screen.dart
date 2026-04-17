import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/site.dart';
import '../../providers/inspections_provider.dart';
import '../inspections/inspections_list_screen.dart';

class SiteDetailScreen extends StatelessWidget {
  final Site site;

  const SiteDetailScreen({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(site.name),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('현장 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _InfoRow(label: '현장명', value: site.name),
                  _InfoRow(label: '주소', value: site.address),
                  _InfoRow(label: '상태', value: _statusLabel(site.status)),
                  if (site.startDate != null) _InfoRow(label: '착공일', value: site.startDate!),
                  if (site.endDate != null) _InfoRow(label: '준공예정', value: site.endDate!),
                  _InfoRow(
                    label: '등록일',
                    value: '${site.createdAt.year}-${site.createdAt.month.toString().padLeft(2, '0')}-${site.createdAt.day.toString().padLeft(2, '0')}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => InspectionsProvider(),
                    child: InspectionsListScreen(siteId: site.id, siteName: site.name),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.assignment),
            label: const Text('점검 기록 보기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active': return '진행중';
      case 'completed': return '완료';
      case 'suspended': return '중단';
      default: return status;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
