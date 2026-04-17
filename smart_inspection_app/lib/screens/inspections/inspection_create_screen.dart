import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inspections_provider.dart';

class InspectionCreateScreen extends StatefulWidget {
  final String siteId;
  final String currentUserId;

  const InspectionCreateScreen({
    super.key,
    required this.siteId,
    required this.currentUserId,
  });

  @override
  State<InspectionCreateScreen> createState() => _InspectionCreateScreenState();
}

class _InspectionCreateScreenState extends State<InspectionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _memoCtrl = TextEditingController();
  String _category = '구조안전';
  String _status = 'pass';
  bool _loading = false;

  final _categories = ['구조안전', '전기설비', '기계설비', '소방설비', '마감공사', '기타'];
  final _statuses = [
    ('pass', '합격'),
    ('fail', '불합격'),
    ('pending', '대기'),
  ];

  @override
  void dispose() {
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final api = context.read<AuthProvider>().api;
    final ok = await context.read<InspectionsProvider>().createInspection(api, {
      'site_id': widget.siteId,
      'inspector_id': widget.currentUserId,
      'category': _category,
      'status': _status,
      'memo': _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('점검 등록 실패'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('점검 기록 등록'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: '점검 분류',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: '점검 결과',
                  prefixIcon: Icon(Icons.check_circle),
                  border: OutlineInputBorder(),
                ),
                items: _statuses
                    .map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _memoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  prefixIcon: Icon(Icons.notes),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('등록하기', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
