import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inspections_provider.dart';
import '../../widgets/stt_text_field.dart';

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
  bool _ocrLoading = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndOcr() async {
    final api = context.read<AuthProvider>().api;
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (xfile == null || !mounted) return;

    setState(() => _ocrLoading = true);
    try {
      final bytes = await xfile.readAsBytes();
      final result = await api.uploadPhoto(
        widget.inspectionId,
        bytes,
        xfile.name,
      );
      final ocr = result['ocr_result'] as String?;
      if (!mounted) return;
      if (ocr != null && ocr.isNotEmpty) {
        final current = _descCtrl.text.trim();
        _descCtrl.text = current.isEmpty ? ocr : '$current\n$ocr';
        _descCtrl.selection = TextSelection.fromPosition(
          TextPosition(offset: _descCtrl.text.length),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OCR 텍스트가 입력되었습니다')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('텍스트를 인식하지 못했습니다')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진 업로드 실패'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              SttTextField(
                controller: _descCtrl,
                labelText: '결함 설명 *',
                hintText: '예: 콘크리트 균열 발견 - 폭 2mm',
                maxLines: 4,
                alignLabelWithHint: true,
                validator: (v) => v!.isEmpty ? '결함 설명을 입력하세요' : null,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _ocrLoading ? null : _pickAndOcr,
                icon: _ocrLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_ocrLoading ? 'OCR 분석 중...' : '사진 촬영 후 텍스트 인식 (OCR)'),
              ),
              const SizedBox(height: 24),
              SizedBox(
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
