import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/editor_provider.dart';
import '../../../../providers/stencil_provider.dart';
import '../../../../core/constants/app_colors.dart';

/// 剪影疊加組件
class StencilOverlayWidget extends ConsumerStatefulWidget {
  const StencilOverlayWidget({super.key});

  @override
  ConsumerState<StencilOverlayWidget> createState() =>
      _StencilOverlayWidgetState();
}

class _StencilOverlayWidgetState
    extends ConsumerState<StencilOverlayWidget> {
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  double _rotation = 0.0;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    // 監聽 editor state 變化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(editorStateProvider);
      setState(() {
        _offset = state.stencilOffset;
        _scale = state.stencilScale;
        _rotation = state.stencilRotation;
        _isFlipped = state.isFlippedHorizontally;
      });
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    // 記錄初始狀態
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // 移動
      _offset += details.focalPointDelta;

      // 縮放
      if (details.scale != 1.0) {
        _scale = (_scale * details.scale).clamp(0.3, 3.0);
      }

      // 旋轉
      _rotation += details.rotation;
    });

    // 更新到 provider
    ref.read(editorStateProvider.notifier).updateStencilOffset(_offset);
    ref.read(editorStateProvider.notifier).updateStencilScale(_scale);
    ref.read(editorStateProvider.notifier).updateStencilRotation(_rotation);
  }

  void _onDoubleTap() {
    // 雙擊翻轉
    setState(() {
      _isFlipped = !_isFlipped;
    });
    ref.read(editorStateProvider.notifier).flipStencil();
  }

  @override
  Widget build(BuildContext context) {
    final selectedStencil = ref.watch(selectedStencilProvider);

    if (selectedStencil == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onDoubleTap: _onDoubleTap,
        child: CustomPaint(
          painter: _StencilOverlayPainter(
            stencilPath: selectedStencil.assetPath,
            offset: _offset,
            scale: _scale,
            rotation: _rotation,
            isFlipped: _isFlipped,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class _StencilOverlayPainter extends CustomPainter {
  final String stencilPath;
  final Offset offset;
  final double scale;
  final double rotation;
  final bool isFlipped;

  _StencilOverlayPainter({
    required this.stencilPath,
    required this.offset,
    required this.scale,
    required this.rotation,
    required this.isFlipped,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 計算中心位置
    final center = Offset(
      size.width / 2 + offset.dx,
      size.height / 2 + offset.dy,
    );

    // 保存畫布狀態
    canvas.save();

    // 移動到中心
    canvas.translate(center.dx, center.dy);

    // 應用翻轉
    if (isFlipped) {
      canvas.scale(-1.0, 1.0);
    }

    // 應用縮放
    canvas.scale(scale);

    // 應用旋轉
    canvas.rotate(rotation);

    // 移動回原點
    canvas.translate(-center.dx, -center.dy);

    // 繪製佔位圖形（實際項目中應該載入實際的PNG剪影）
    _drawPlaceholderStencil(canvas, size, center);

    // 恢復畫布狀態
    canvas.restore();
  }

  void _drawPlaceholderStencil(Canvas canvas, Size size, Offset center) {
    // 繪製一個貓咪形狀的佔位剪影
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final fillPaint = Paint()
      ..color = Colors.transparent
      ..style = PaintingStyle.fill;

    // 貓咪身體（橢圓形）
    final bodyRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + 50),
      width: 150 * scale,
      height: 120 * scale,
    );
    canvas.drawOval(bodyRect, fillPaint);
    canvas.drawOval(bodyRect, paint);

    // 貓咪頭部（圓形）
    final headCenter = Offset(center.dx, center.dy - 30);
    final headRadius = 50.0 * scale;
    
    // 頭部輪廓
    canvas.drawCircle(headCenter, headRadius, fillPaint);
    canvas.drawCircle(headCenter, headRadius, paint);

    // 耳朵（兩個三角形）
    final leftEarPath = Path()
      ..moveTo(headCenter.dx - 40 * scale, headCenter.dy - 30 * scale)
      ..lineTo(headCenter.dx - 50 * scale, headCenter.dy - 70 * scale)
      ..lineTo(headCenter.dx - 20 * scale, headCenter.dy - 40 * scale)
      ..close();
    canvas.drawPath(leftEarPath, fillPaint);
    canvas.drawPath(leftEarPath, paint);

    final rightEarPath = Path()
      ..moveTo(headCenter.dx + 40 * scale, headCenter.dy - 30 * scale)
      ..lineTo(headCenter.dx + 50 * scale, headCenter.dy - 70 * scale)
      ..lineTo(headCenter.dx + 20 * scale, headCenter.dy - 40 * scale)
      ..close();
    canvas.drawPath(rightEarPath, fillPaint);
    canvas.drawPath(rightEarPath, paint);

    // 眼睛（兩個小橢圓）
    final eyePaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headCenter.dx - 15 * scale, headCenter.dy - 5 * scale),
        width: 15 * scale,
        height: 20 * scale,
      ),
      eyePaint,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headCenter.dx + 15 * scale, headCenter.dy - 5 * scale),
        width: 15 * scale,
        height: 20 * scale,
      ),
      eyePaint,
    );

    // 尾巴
    final tailPath = Path()
      ..moveTo(center.dx + 70 * scale, center.dy + 80 * scale)
      ..quadraticBezierTo(
        center.dx + 120 * scale,
        center.dy + 50 * scale,
        center.dx + 100 * scale,
        center.dy,
      );
    canvas.drawPath(tailPath, paint);
  }

  @override
  bool shouldRepaint(covariant _StencilOverlayPainter oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.scale != scale ||
        oldDelegate.rotation != rotation ||
        oldDelegate.isFlipped != isFlipped;
  }
}
