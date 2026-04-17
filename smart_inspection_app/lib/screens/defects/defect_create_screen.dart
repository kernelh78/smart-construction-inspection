import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inspections_provider.dart';

class DefectCreateScreen extends StatefulWidget {
  final String inspectionId;

  const DefectCreateScreen({super.key, required this.inspectionId});

  @override
  State<DefectCreateScreen> createState() => _DefectCreateScreenState();
}

class _DefectCreateScreenState extends State<DefectCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descCtrl = TextEditingController();
  String _severity = 'major';
  bool _loading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final api = context.read<AuthProvider>().api;
    final ok = await context.read<InspectionsProvider>().createDefect(
          api,
          widget.inspectionId,
          _severity,
          _descCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('결함 등록 실패'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결함 등록'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _severity,
                decoration: const InputDecoration(
                  labelText: '심각도',
                  prefixIcon: Icon(Icons.warning),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'critical', child: Text('심각 (Critical)')),
                  DropdownMenuItem(value: 'major', child: Text('주요 (Major)')),
                  DropdownMenuItem(value: 'minor', child: Text('경미 (Minor)')),
                ],
                onChanged: (v) => setState(() => _severity = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '결함 설명 *',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  hintText: '예: 콘크리트 균열 발견 - 폭 2mm',
                ),
                validator: (v) => v!.isEmpty ? '결함 설명을 입력하세요' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('결함 등록', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
