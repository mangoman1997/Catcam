import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/editor_provider.dart';
import '../../../../providers/stencil_provider.dart';
import '../../../../core/constants/app_colors.dart';

/// 剪影疊加組件 - 在相機預覽上顯示剪影作為拍照引導
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
  ui.Image? _stencilImage;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(editorStateProvider);
      setState(() {
        _offset = state.stencilOffset;
        _scale = state.stencilScale;
        _rotation = state.stencilRotation;
        _isFlipped = state.isFlippedHorizontally;
      });
      _loadStencil();
    });
  }

  Future<void> _loadStencil() async {
    final selectedStencil = ref.read(selectedStencilProvider);
    if (selectedStencil == null) return;

    try {
      final data = await DefaultAssetBundle.of(context).load(selectedStencil.assetPath);
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
    }
  }

  void _onScaleStart(ScaleStartDetails details) {}

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _offset += details.focalPointDelta;
      if (details.scale != 1.0) {
        _scale = (_scale * details.scale).clamp(0.3, 3.0);
      }
      _rotation += details.rotation;
    });

    ref.read(editorStateProvider.notifier).updateStencilOffset(_offset);
    ref.read(editorStateProvider.notifier).updateStencilScale(_scale);
    ref.read(editorStateProvider.notifier).updateStencilRotation(_rotation);
  }

  void _onDoubleTap() {
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
        child: _imageLoaded && _stencilImage != null
            ? CustomPaint(
                painter: _StencilGuidePainter(
                  stencilImage: _stencilImage!,
                  offset: _offset,
                  scale: _scale,
                  rotation: _rotation,
                  isFlipped: _isFlipped,
                ),
              )
            : Container(
                color: Colors.transparent,
              ),
      ),
    );
  }
}

/// 剪影引導畫家 - 顯示半透明填充的剪影形狀作為拍照引導
class _StencilGuidePainter extends CustomPainter {
  final ui.Image stencilImage;
  final Offset offset;
  final double scale;
  final double rotation;
  final bool isFlipped;

  _StencilGuidePainter({
    required this.stencilImage,
    required this.offset,
    required this.scale,
    required this.rotation,
    required this.isFlipped,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2 + offset.dx,
      size.height / 2 + offset.dy,
    );

    // 保存狀態
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

    // 計算目標區域
    final stencilSize = 300.0;
    final dstRect = Rect.fromCenter(
      center: center,
      width: stencilSize,
      height: stencilSize,
    );

    // 方法1：繪製半透明填充的剪影（作為可見引導）
    // 使用 srcATop 混合模式：只在剪影有內容的地方繪製
    canvas.saveLayer(dstRect, Paint());

    // 先填充一個半透明白色
    final fillPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(dstRect, fillPaint);

    // 然後用 dstIn 只保留剪影形狀內的白色
    final maskPaint = Paint()
      ..blendMode = BlendMode.dstIn
      ..sourceImage = stencilImage
      ..filterQuality = FilterQuality.high;
    
    canvas.drawImageRect(
      stencilImage,
      Rect.fromLTWH(0, 0, stencilImage.width.toDouble(), stencilImage.height.toDouble()),
      Rect.fromLTWH(0, 0, stencilSize, stencilSize),
      maskPaint,
    );

    canvas.restore();

    // 方法2：再繪製一個白色邊框
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..sourceImage = stencilImage
      ..filterQuality = FilterQuality.high;
    
    canvas.drawImageRect(
      stencilImage,
      Rect.fromLTWH(0, 0, stencilImage.width.toDouble(), stencilImage.height.toDouble()),
      dstRect,
      Paint()
        ..blendMode = BlendMode.dstOut
        ..sourceImage = stencilImage
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );

    // 恢復狀態
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StencilGuidePainter oldDelegate) {
    return oldDelegate.offset != offset ||
        oldDelegate.scale != scale ||
        oldDelegate.rotation != rotation ||
        oldDelegate.isFlipped != isFlipped ||
        oldDelegate.stencilImage != stencilImage;
  }
}
