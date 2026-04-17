import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inspection.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inspections_provider.dart';
import '../defects/defect_create_screen.dart';

class InspectionDetailScreen extends StatefulWidget {
  final Inspection inspection;

  const InspectionDetailScreen({super.key, required this.inspection});

  @override
  State<InspectionDetailScreen> createState() => _InspectionDetailScreenState();
}

class _InspectionDetailScreenState extends State<InspectionDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchDefects());
  }

  void _fetchDefects() {
    final api = context.read<AuthProvider>().api;
    context.read<InspectionsProvider>().fetchDefects(api, widget.inspection.id);
  }

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
    final provider = context.watch<InspectionsProvider>();
    final inspection = widget.inspection;

    return Scaffold(
      appBar: AppBar(
        title: Text('점검 상세 - ${inspection.category}'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DefectCreateScreen(inspectionId: inspection.id),
            ),
          );
          _fetchDefects();
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.warning, color: Colors.white),
        label: const Text('결함 등록', style: TextStyle(color: Colors.white)),
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
                  const Text('점검 정보', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Divider(),
                  _InfoRow(label: '분류', value: inspection.category),
                  _InfoRow(label: '결과', value: _statusLabel(inspection.status)),
                  _InfoRow(label: '메모', value: inspection.memo ?? '-'),
                  _InfoRow(
                    label: '점검일시',
                    value: inspection.inspectedAt.toString().substring(0, 16),
                  ),
                  _InfoRow(label: '동기화', value: inspection.isSynced ? '완료' : '미동기화'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('결함 목록', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (provider.loading) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const Divider(),
                  if (provider.defects.isEmpty && !provider.loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: Text('등록된 결함이 없습니다.', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ...provider.defects.map((d) => ListTile(
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
                          title: Text(d.description),
                          subtitle: Text(
                            d.isResolved ? '해결됨' : '미해결',
                            style: TextStyle(color: d.isResolved ? Colors.green : Colors.red),
                          ),
                          trailing: Text(
                            d.createdAt.toString().substring(0, 10),
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pass': return '합격';
      case 'fail': return '불합격';
      case 'pending': return '대기';
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
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
