import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'dart:typed_data';

class NewSignatureWidget extends StatefulWidget {
  final Function(String) onSave;
  final bool disabled;
  final String? initialSignature;

  const NewSignatureWidget({
    super.key,
    required this.onSave,
    this.disabled = false,
    this.initialSignature,
  });

  @override
  State<NewSignatureWidget> createState() => _NewSignatureWidgetState();
}

class _NewSignatureWidgetState extends State<NewSignatureWidget> {
  late SignatureController _controller;
  bool _hasSignature = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.blue.shade700,
      exportBackgroundColor: Colors.white,
    );
    
    _controller.addListener(() {
      setState(() {
        _hasSignature = _controller.isNotEmpty;
      });
      _saveSignature();
    });

    if (widget.initialSignature != null && widget.initialSignature!.isNotEmpty) {
      _hasSignature = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_controller.isEmpty) {
      widget.onSave('');
      return;
    }

    try {
      final Uint8List? data = await _controller.toPngBytes();
      if (data != null) {
        final String base64Image = base64Encode(data);
        widget.onSave(base64Image);
      }
    } catch (e) {
      debugPrint('Error saving signature: $e');
    }
  }

  void _clearSignature() {
    if (widget.disabled) return;
    _controller.clear();
    setState(() {
      _hasSignature = false;
    });
    widget.onSave('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Signature(
              controller: _controller,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.disabled ? 'החתימה נעולה' : 'חתום כאן באמצעות האצבע או העכבר',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        if (_hasSignature && !widget.disabled)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _clearSignature,
              icon: const Icon(Icons.refresh),
              label: const Text('נקה חתימה'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                foregroundColor: isDark ? Colors.grey[300] : Colors.grey[700],
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
