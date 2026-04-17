import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inspections_provider.dart';
import 'inspection_detail_screen.dart';
import 'inspection_create_screen.dart';

class InspectionsListScreen extends StatefulWidget {
  final String siteId;
  final String siteName;

  const InspectionsListScreen({super.key, required this.siteId, required this.siteName});

  @override
  State<InspectionsListScreen> createState() => _InspectionsListScreenState();
}

class _InspectionsListScreenState extends State<InspectionsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  void _fetch() {
    final api = context.read<AuthProvider>().api;
    context.read<InspectionsProvider>().fetchInspections(api, siteId: widget.siteId);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pass': return Colors.green;
      case 'fail': return Colors.red;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pass': return '합격';
      case 'fail': return '불합격';
      case 'pending': return '대기';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InspectionsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.siteName} - 점검 기록'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetch),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InspectionCreateScreen(
                siteId: widget.siteId,
                currentUserId: context.read<AuthProvider>().currentUser!.id,
              ),
            ),
          );
          _fetch();
        },
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(child: Text('오류: ${provider.error}'))
              : provider.inspections.isEmpty
                  ? const Center(child: Text('점검 기록이 없습니다.'))
                  : RefreshIndicator(
                      onRefresh: () async => _fetch(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: provider.inspections.length,
                        itemBuilder: (ctx, i) {
                          final inspection = provider.inspections[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _statusColor(inspection.status),
                                child: const Icon(Icons.assignment, color: Colors.white),
                              ),
                              title: Text(inspection.category,
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                inspection.memo ?? '메모 없음',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _statusColor(inspection.status),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _statusLabel(inspection.status),
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${inspection.inspectedAt.month}/${inspection.inspectedAt.day}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InspectionDetailScreen(inspection: inspection),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
