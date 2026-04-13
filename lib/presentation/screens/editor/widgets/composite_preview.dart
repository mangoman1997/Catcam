import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    if (widget.state.selectedStencil == null) {
      return;
    }

    try {
      debugPrint('Loading stencil: ${widget.state.selectedStencil!.assetPath}');
      final data = await rootBundle.load(widget.state.selectedStencil!.assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      debugPrint('Stencil loaded: ${frame.image.width}x${frame.image.height}');
      
      if (mounted) {
        setState(() {
          _stencilImage = frame.image;
          _imagesLoaded = _stencilImage != null && _capturedImage != null;
        });
      }
    } catch (e, stack) {
      debugPrint('Failed to load stencil: $e\n$stack');
      if (mounted) {
        setState(() {
          _stencilImage = null;
          _imagesLoaded = _stencilImage != null && _capturedImage != null;
        });
      }
    }
  }

  Future<void> _loadCapturedImage() async {
    if (widget.state.capturedImage == null) {
      return;
    }

    try {
      final bytes = widget.state.capturedImage!;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      debugPrint('Captured image loaded: ${frame.image.width}x${frame.image.height}');
      
      if (mounted) {
        setState(() {
          _capturedImage = frame.image;
          _imagesLoaded = _stencilImage != null && _capturedImage != null;
        });
      }
    } catch (e, stack) {
      debugPrint('Failed to load captured image: $e\n$stack');
      if (mounted) {
        setState(() {
          _capturedImage = null;
          _imagesLoaded = _stencilImage != null && _capturedImage != null;
        });
      }
    }
  }

  void _updateLoadState() {
    // This is now handled inside load methods
  }

  @override
  Widget build(BuildContext context) {
    final editorState = widget.state;

    // 確保圖片被載入
    if (editorState.capturedImage != null && _capturedImage == null) {
      _loadCapturedImage();
    }
    if (editorState.selectedStencil != null && _stencilImage == null) {
      _loadStencilImage();
    }

    // 沒有照片，顯示背景色
    if (editorState.capturedImage == null) {
      return Container(color: AppColors.cameraBackground);
    }

    // 沒有剪影，直接顯示照片
    if (!_imagesLoaded || _stencilImage == null || _capturedImage == null) {
      return Image.memory(
        editorState.capturedImage!,
        fit: BoxFit.cover,
      );
    }

    // 有剪影：把照片裁剪成貓咪形狀
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
    
    // 不需要繪製邊框（只有拍照預覽需要）
  }

  @override
  bool shouldRepaint(covariant _CatCropPainter oldDelegate) {
    return oldDelegate.stencilImage != stencilImage ||
        oldDelegate.capturedImage != capturedImage ||
        oldDelegate.targetSize != targetSize;
  }
}
