import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/editor_state.dart';
import '../../../../providers/editor_provider.dart';
import '../../../../core/constants/app_colors.dart';

/// 合成預覽組件
class CompositePreview extends ConsumerStatefulWidget {
  final EditorState state;

  const CompositePreview({
    super.key,
    required this.state,
  });

  @override
  ConsumerState<CompositePreview> createState() => _CompositePreviewState();
}

class _CompositePreviewState extends ConsumerState<CompositePreview> {
  ui.Image? _stencilImage;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStencilImage();
  }

  @override
  void didUpdateWidget(CompositePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedStencil?.assetPath != 
        widget.state.selectedStencil?.assetPath) {
      _loadStencilImage();
    }
  }

  Future<void> _loadStencilImage() async {
    if (widget.state.selectedStencil == null) {
      setState(() {
        _stencilImage = null;
        _imageLoaded = false;
      });
      return;
    }

    try {
      final assetPath = widget.state.selectedStencil!.assetPath;
      final data = await DefaultAssetBundle.of(ref.context).load(assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
      if (mounted) {
        setState(() {
          _stencilImage = frame.image;
          _imageLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load stencil: $e');
      if (mounted) {
        setState(() {
          _stencilImage = null;
          _imageLoaded = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = widget.state;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 底層：背景色（剪影外部顯示這個顏色）
        Container(color: AppColors.cameraBackground),

        // 中間層：如果有剪影應用，顯示經過剪影遮罩的圖片
        if (editorState.capturedImage != null)
          _buildMaskedImage(editorState),

        // 頂層：如果有剪影，顯示剪影輪廓線
        if (_imageLoaded && editorState.selectedStencil != null)
          _buildStencilOverlay(editorState),

        // 文字
        if (editorState.hasText && editorState.textPosition != null)
          Positioned(
            left: editorState.textPosition!.dx,
            top: editorState.textPosition!.dy,
            child: Text(
              editorState.text!,
              style: TextStyle(
                color: editorState.textColor ?? Colors.white,
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

  /// 構建被剪影遮罩的圖片
  Widget _buildMaskedImage(EditorState state) {
    if (!_imageLoaded || _stencilImage == null) {
      // 如果沒有剪影，直接顯示原圖
      return Image.memory(
        state.capturedImage!,
        fit: BoxFit.cover,
      );
    }

    // 使用剪影作為遮罩：黑色部分 = 顯示圖片，透明部分 = 顯示背景
    return ShaderMask(
      shaderCallback: (bounds) {
        return ImageShader(
          _stencilImage!,
          TileMode.clamp,
          TileMode.clamp,
          Matrix4.identity().storage,
        );
      },
      blendMode: BlendMode.dstIn,
      child: Image.memory(
        state.capturedImage!,
        fit: BoxFit.cover,
        width: bounds.width,
        height: bounds.height,
      ),
    );
  }

  Size? get bounds => null;

  /// 構建剪影輪廓線疊加
  Widget _buildStencilOverlay(EditorState state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // 計算剪影位置（居中顯示）
    final stencilSize = 300.0 * state.stencilScale;
    final left = screenWidth / 2 - stencilSize / 2 + state.stencilOffset.dx;
    final top = screenHeight / 2 - stencilSize / 2 + state.stencilOffset.dy;

    Widget stencilWidget = Transform.scale(
      scale: state.stencilScale,
      child: Transform.rotate(
        angle: state.stencilRotation,
        child: state.isFlippedHorizontally
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(-1.0, 1.0),
                child: Image.asset(
                  state.selectedStencil!.assetPath,
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
              )
            : Image.asset(
                state.selectedStencil!.assetPath,
                width: 300,
                height: 300,
                fit: BoxFit.contain,
              ),
      ),
    );

    return Positioned(
      left: left,
      top: top,
      child: stencilWidget,
    );
  }
}

/// 疊加層：輪廓線和填色效果（可選）
class _StencilOverlay extends ConsumerWidget {
  final EditorState state;

  const _StencilOverlay({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.selectedStencil == null) return const SizedBox();

    return CustomPaint(
      painter: _StencilOutlinePainter(
        color: state.showOutline ? state.outlineColor : Colors.transparent,
        thickness: state.outlineThickness,
      ),
      size: const Size(300, 300),
    );
  }
}

class _StencilOutlinePainter extends CustomPainter {
  final Color color;
  final double thickness;

  _StencilOutlinePainter({
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (color == Colors.transparent || thickness == 0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;

    // 繪製貓咪形狀輪廓
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

  @override
  bool shouldRepaint(covariant _StencilOutlinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.thickness != thickness;
  }
}
