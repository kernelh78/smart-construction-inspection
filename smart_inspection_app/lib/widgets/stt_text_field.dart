import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// 마이크 버튼이 내장된 텍스트 필드. 음성 인식 결과를 컨트롤러에 자동 입력합니다.
class SttTextField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final int maxLines;
  final String? Function(String?)? validator;
  final bool alignLabelWithHint;

  const SttTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.maxLines = 1,
    this.validator,
    this.alignLabelWithHint = false,
  });

  @override
  State<SttTextField> createState() => _SttTextFieldState();
}

class _SttTextFieldState extends State<SttTextField> {
  final SpeechToText _stt = SpeechToText();
  bool _listening = false;
  bool _available = false;

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    final available = await _stt.initialize(
      onError: (_) => setState(() => _listening = false),
    );
    if (mounted) setState(() => _available = available);
  }

  Future<void> _toggleListening() async {
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    await _stt.listen(
      localeId: 'ko_KR',
      onResult: (result) {
        widget.controller.text = result.recognizedWords;
        widget.controller.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.controller.text.length),
        );
      },
    );
    setState(() => _listening = true);
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      maxLines: widget.maxLines,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        border: const OutlineInputBorder(),
        alignLabelWithHint: widget.alignLabelWithHint,
        suffixIcon: _available
            ? IconButton(
                icon: Icon(
                  _listening ? Icons.mic : Icons.mic_none,
                  color: _listening ? Colors.red : null,
                ),
                tooltip: _listening ? '듣는 중 (탭하여 중지)' : '음성 입력',
                onPressed: _toggleListening,
              )
            : null,
      ),
    );
  }
}
