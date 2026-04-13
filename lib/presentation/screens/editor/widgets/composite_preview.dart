import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/editor_state.dart';
import '../../../../providers/editor_provider.dart';
import '../../../../core/constants/app_colors.dart';

/// 合成預覽組件 - 把照片裁剪成貓咪形狀
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
  ui.Image? _capturedImage;
  bool _imagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStencilImage();
    _loadCapturedImage();
  }

  @override
  void didUpdateWidget(CompositePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.selectedStencil?.assetPath != 
        widget.state.selectedStencil?.assetPath) {
      _loadStencilImage();
    }
    if (oldWidget.state.capturedImage != widget.state.capturedImage) {
      _loadCapturedImage();
    }
  }

  Future<void> _loadStencilImage() async {
    debugPrint('_loadStencilImage called, selectedStencil: ${widget.state.selectedStencil?.name ?? "null"}');
    
    if (widget.state.selectedStencil == null) {
      debugPrint('No stencil selected, skipping load');
      setState(() => _updateLoadState());
      return;
    }

    try {
      debugPrint('Loading stencil from: ${widget.state.selectedStencil!.assetPath}');
      final data = await DefaultAssetBundle.of(context)
          .load(widget.state.selectedStencil!.assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      debugPrint('Stencil loaded: ${frame.image.width}x${frame.image.height}');
      
      if (mounted) {
        _stencilImage = frame.image;
        _updateLoadState();
      }
    } catch (e) {
      debugPrint('Failed to load stencil: $e');
      if (mounted) {
        _stencilImage = null;
        _updateLoadState();
      }
    }
  }

  Future<void> _loadCapturedImage() async {
    if (widget.state.capturedImage == null) {
      setState(() => _updateLoadState());
      return;
    }

    try {
      final bytes = widget.state.capturedImage!;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
      if (mounted) {
        _capturedImage = frame.image;
        _updateLoadState();
      }
    } catch (e) {
      debugPrint('Failed to load captured image: $e');
      if (mounted) {
        _capturedImage = null;
        _updateLoadState();
      }
    }
  }

  void _updateLoadState() {
    _imagesLoaded = _stencilImage != null && _capturedImage != null;
  }

  @override
  Widget build(BuildContext context) {
    final editorState = widget.state;

    debugPrint('CompositePreview.build: capturedImage=${editorState.capturedImage != null}, '
        'selectedStencil=${editorState.selectedStencil?.name ?? "null"}, '
        'stencilImage=${_stencilImage != null}, '
        'capturedImageLoaded=${_capturedImage != null}, '
        'imagesLoaded=$_imagesLoaded');

    // 沒有照片，顯示背景色
    if (editorState.capturedImage == null) {
      return Container(color: AppColors.cameraBackground);
    }

    // 沒有剪影，直接顯示照片
    if (!_imagesLoaded || _stencilImage == null || _capturedImage == null) {
      debugPrint('Showing raw image (no stencil applied)');
      return Image.memory(
        editorState.capturedImage!,
        fit: BoxFit.cover,
      );
    }

    // 有剪影：把照片裁剪成貓咪形狀
    debugPrint('Applying cat stencil mask!');
    return _CatCropWidget(
      stencilImage: _stencilImage!,
      capturedImage: _capturedImage!,
    );
  }
}

/// 貓咪裁剪組件
class _CatCropWidget extends StatelessWidget {
  final ui.Image stencilImage;
  final ui.Image capturedImage;

  const _CatCropWidget({
    required this.stencilImage,
    required this.capturedImage,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        return Stack(
          fit: StackFit.expand,
          children: [
            // 背景色
            Container(color: AppColors.cameraBackground),
            
            // 裁剪後的照片
            CustomPaint(
              painter: _CatCropPainter(
                stencilImage: stencilImage,
                capturedImage: capturedImage,
                targetSize: size,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 貓咪裁剪畫家
class _CatCropPainter extends CustomPainter {
  final ui.Image stencilImage;
  final ui.Image capturedImage;
  final Size targetSize;

  _CatCropPainter({
    required this.stencilImage,
    required this.capturedImage,
    required this.targetSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 計算剪影的位置和大小（居中，完整顯示）
    final stencilScaleX = size.width / stencilImage.width;
    final stencilScaleY = size.height / stencilImage.height;
    final stencilScale = stencilScaleX < stencilScaleY ? stencilScaleX : stencilScaleY;
    final stencilOffsetX = (size.width - stencilImage.width * stencilScale) / 2;
    final stencilOffsetY = (size.height - stencilImage.height * stencilScale) / 2;

    // 計算照片的位置和大小（填滿整個區域）
    final photoScaleX = size.width / capturedImage.width;
    final photoScaleY = size.height / capturedImage.height;
    final photoScale = photoScaleX > photoScaleY ? photoScaleX : photoScaleY;
    final photoOffsetX = (size.width - capturedImage.width * photoScale) / 2;
    final photoOffsetY = (size.height - capturedImage.height * photoScale) / 2;

    // 使用 saveLayer + BlendMode.dstIn 來實現裁剪
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    // 第一層：照片
    canvas.saveLayer(rect, Paint());
    canvas.save();
    canvas.translate(photoOffsetX, photoOffsetY);
    canvas.scale(photoScale);
    canvas.drawImage(capturedImage, Offset.zero, Paint());
    canvas.restore();
    
    // 第二層：剪影，使用 dstIn 混合模式
    canvas.saveLayer(rect, Paint()..blendMode = BlendMode.dstIn);
    canvas.save();
    canvas.translate(stencilOffsetX, stencilOffsetY);
    canvas.scale(stencilScale);
    canvas.drawImage(stencilImage, Offset.zero, Paint());
    canvas.restore();
    canvas.restore(); // dstIn
    
    canvas.restore(); // 主 layer
    
    // 繪製白色邊框
    _drawStencilBorder(canvas, size, stencilScale, stencilOffsetX, stencilOffsetY);
  }

  void _drawStencilBorder(Canvas canvas, Size size, double scale, double offsetX, double offsetY) {
    // 根據 stencil 的形狀繪製邊框
    // 這裡用一個近似的貓咪形狀
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final w = stencilImage.width * scale;
    final h = stencilImage.height * scale;

    // 頭部
    final headRadius = w * 0.2;
    canvas.drawCircle(
      Offset(cx, cy - h * 0.15),
      headRadius,
      borderPaint,
    );

    // 身體
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy + h * 0.2),
        width: w * 0.4,
        height: h * 0.35,
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CatCropPainter oldDelegate) {
    return oldDelegate.stencilImage != stencilImage ||
        oldDelegate.capturedImage != capturedImage ||
        oldDelegate.targetSize != targetSize;
  }
}
