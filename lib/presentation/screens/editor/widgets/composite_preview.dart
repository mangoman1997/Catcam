import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/editor_state.dart';
import '../../../../providers/editor_provider.dart';
import '../../../../core/constants/app_colors.dart';

/// 合成預覽組件
class CompositePreview extends ConsumerWidget {
  final EditorState state;

  const CompositePreview({
    super.key,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 拍攝的圖片
        if (state.capturedImage != null)
          Image.memory(
            state.capturedImage!,
            fit: BoxFit.cover,
          ),

        // 應用濾鏡
        if (state.filterType != FilterType.none)
          ColorFiltered(
            colorFilter: _getColorFilter(state.filterType),
            child: Container(),
          ),

        // 剪影疊加
        if (state.selectedStencil != null)
          Positioned(
            left: MediaQuery.of(context).size.width / 2 -
                150 * state.stencilScale +
                state.stencilOffset.dx,
            top: MediaQuery.of(context).size.height / 2 -
                150 * state.stencilScale +
                state.stencilOffset.dy,
            child: Transform.scale(
              scale: state.stencilScale,
              child: Transform.rotate(
                angle: state.stencilRotation,
                child: state.isFlippedHorizontally
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..scale(-1.0, 1.0),
                        child: _buildStencil(state),
                      )
                    : _buildStencil(state),
              ),
            ),
          ),

        // 文字
        if (state.hasText && state.textPosition != null)
          Positioned(
            left: state.textPosition!.dx,
            top: state.textPosition!.dy,
            child: Text(
              state.text!,
              style: TextStyle(
                color: state.textColor ?? Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStencil(EditorState state) {
    return CustomPaint(
      painter: _StencilPreviewPainter(
        outlineColor: state.showOutline ? state.outlineColor : Colors.transparent,
        outlineThickness: state.outlineThickness,
        outlineStyle: state.outlineStyle,
      ),
      size: const Size(300, 300),
    );
  }

  ColorFilter _getColorFilter(FilterType type) {
    switch (type) {
      case FilterType.none:
        return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
      case FilterType.blackAndWhite:
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.warm:
        return const ColorFilter.matrix([
          1.2, 0, 0, 0, 0,
          0, 1.1, 0, 0, 0,
          0, 0, 0.9, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.cool:
        return const ColorFilter.matrix([
          0.9, 0, 0, 0, 0,
          0, 1.0, 0, 0, 0,
          0, 0, 1.2, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.vintage:
        return const ColorFilter.matrix([
          0.9, 0.1, 0.1, 0, 10,
          0.1, 0.8, 0.1, 0, 10,
          0.1, 0.1, 0.6, 0, 20,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.HDR:
        return const ColorFilter.matrix([
          1.3, 0, 0, 0, -20,
          0, 1.3, 0, 0, -20,
          0, 0, 1.3, 0, -20,
          0, 0, 0, 1, 0,
        ]);
    }
  }
}

class _StencilPreviewPainter extends CustomPainter {
  final Color outlineColor;
  final double outlineThickness;
  final OutlineStyle outlineStyle;

  _StencilPreviewPainter({
    required this.outlineColor,
    required this.outlineThickness,
    required this.outlineStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = outlineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = outlineThickness
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (outlineStyle == OutlineStyle.dashed) {
      _drawDashedOval(
        canvas,
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: 200,
          height: 180,
        ),
        paint,
      );
    } else {
      // 繪製貓咪形狀
      _drawCatShape(canvas, size, paint);
    }
  }

  void _drawCatShape(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width / 2, size.height / 2);

    // 頭部
    canvas.drawCircle(
      Offset(center.dx, center.dy - 20),
      60,
      paint,
    );

    // 身體
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 60),
        width: 140,
        height: 100,
      ),
      paint,
    );

    // 左耳
    final leftEarPath = Path()
      ..moveTo(center.dx - 45, center.dy - 55)
      ..lineTo(center.dx - 55, center.dy - 100)
      ..lineTo(center.dx - 20, center.dy - 60)
      ..close();
    canvas.drawPath(leftEarPath, paint);

    // 右耳
    final rightEarPath = Path()
      ..moveTo(center.dx + 45, center.dy - 55)
      ..lineTo(center.dx + 55, center.dy - 100)
      ..lineTo(center.dx + 20, center.dy - 60)
      ..close();
    canvas.drawPath(rightEarPath, paint);

    // 尾巴
    final tailPath = Path()
      ..moveTo(center.dx + 70, center.dy + 90)
      ..quadraticBezierTo(
        center.dx + 120,
        center.dy + 60,
        center.dx + 100,
        center.dy + 10,
      );
    canvas.drawPath(tailPath, paint);
  }

  void _drawDashedOval(Canvas canvas, Rect rect, Paint paint) {
    const dashWidth = 10.0;
    const dashSpace = 5.0;

    // 實現虛線效果
    final path = Path()..addOval(rect);
    final pathMetrics = path.computeMetrics();

    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final start = distance;
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        final extractPath = metric.extractPath(start, end.toDouble());
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StencilPreviewPainter oldDelegate) {
    return oldDelegate.outlineColor != outlineColor ||
        oldDelegate.outlineThickness != outlineThickness ||
        oldDelegate.outlineStyle != outlineStyle;
  }
}
