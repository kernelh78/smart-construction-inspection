import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/inspection.dart';
import '../../models/inspection_photo.dart';
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
  List<InspectionPhoto> _photos = [];
  bool _photosLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDefects();
      _fetchPhotos();
    });
  }

  void _fetchDefects() {
    final api = context.read<AuthProvider>().api;
    context.read<InspectionsProvider>().fetchDefects(api, widget.inspection.id);
  }

  Future<void> _fetchPhotos() async {
    setState(() => _photosLoading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final photos = await api.getPhotos(widget.inspection.id);
      if (mounted) setState(() => _photos = photos);
    } catch (_) {
      // 사진 목록 로드 실패 시 무시
    } finally {
      if (mounted) setState(() => _photosLoading = false);
    }
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
          final inspProv = context.read<InspectionsProvider>();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: inspProv,
                child: DefectCreateScreen(inspectionId: inspection.id),
              ),
            ),
          );
          _fetchDefects();
          _fetchPhotos();
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.warning, color: Colors.white),
        label: const Text('결함 등록', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 점검 정보 카드
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

          // 첨부 사진 카드
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('첨부 사진', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (_photosLoading)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                  const Divider(),
                  if (_photos.isEmpty && !_photosLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text('첨부된 사진이 없습니다.', style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _photos.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => _PhotoTile(photo: _photos[i]),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 결함 목록 카드
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
                      if (provider.loading)
                        const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
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

class _PhotoTile extends StatelessWidget {
  final InspectionPhoto photo;

  const _PhotoTile({required this.photo});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: photo.url != null
            ? Image.network(
                photo.url!,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 110,
      height: 110,
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, color: Colors.grey),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('사진 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photo.url != null)
              Image.network(photo.url!, errorBuilder: (_, _, _) => const Icon(Icons.broken_image)),
            if (photo.ocrResult != null && photo.ocrResult!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('OCR 인식 텍스트', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(photo.ocrResult!, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
        ],
      ),
    );
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
