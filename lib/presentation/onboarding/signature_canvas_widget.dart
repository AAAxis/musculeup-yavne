import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/rendering.dart';

class SignatureCanvasWidget extends StatefulWidget {
  final Function(String) onSave;
  final bool disabled;
  final String? initialSignature;

  const SignatureCanvasWidget({
    super.key,
    required this.onSave,
    this.disabled = false,
    this.initialSignature,
  });

  @override
  State<SignatureCanvasWidget> createState() => _SignatureCanvasWidgetState();
}

class _SignatureCanvasWidgetState extends State<SignatureCanvasWidget> {
  final List<Offset?> _points = [];
  final GlobalKey _canvasKey = GlobalKey();
  bool _hasSignature = false;
  bool _isDrawing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSignature != null && widget.initialSignature!.isNotEmpty) {
      _hasSignature = true;
    }
  }


  Future<void> _saveSignature() async {
    try {
      final RenderRepaintBoundary boundary = 
          _canvasKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        final String base64Image = base64Encode(pngBytes);
        widget.onSave(base64Image);
      }
    } catch (e) {
      debugPrint('Error saving signature: $e');
    }
  }

  void _clearSignature() {
    if (widget.disabled) return;
    
    setState(() {
      _points.clear();
      _hasSignature = false;
    });
    widget.onSave('');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey[900]! : Colors.white;
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
            color: backgroundColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: RepaintBoundary(
              key: _canvasKey,
              child: GestureDetector(
                onPanStart: (details) {
                  if (widget.disabled) return;
                  final RenderBox renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(details.globalPosition);
                  setState(() {
                    _points.add(localPosition);
                    _hasSignature = true;
                    _isDrawing = true;
                  });
                },
                onPanUpdate: (details) {
                  if (widget.disabled || !_isDrawing) return;
                  final RenderBox renderBox = _canvasKey.currentContext!.findRenderObject() as RenderBox;
                  final localPosition = renderBox.globalToLocal(details.globalPosition);
                  setState(() {
                    _points.add(localPosition);
                  });
                },
                onPanEnd: (details) {
                  if (widget.disabled) return;
                  setState(() {
                    _points.add(null); // Add null to separate strokes
                    _isDrawing = false;
                  });
                  _saveSignature();
                },
                child: CustomPaint(
                  painter: SignaturePainter(_points, isDark),
                  size: const Size(double.infinity, 200),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    color: backgroundColor,
                  ),
                ),
              ),
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
      ],
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final bool isDark;

  SignaturePainter(this.points, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = isDark ? Colors.white : Colors.blue.shade700
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}

