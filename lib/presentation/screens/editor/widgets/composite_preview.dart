import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
      setState(() => _updateLoadState());
      return;
    }

    try {
      final data = await DefaultAssetBundle.of(ref.context)
          .load(widget.state.selectedStencil!.assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
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

    return Stack(
      fit: StackFit.expand,
      children: [
        // 底層：背景色
        Container(color: AppColors.cameraBackground),

        // 圖片層
        if (editorState.capturedImage != null)
          _buildImageLayer(editorState),

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

  Widget _buildImageLayer(EditorState state) {
    // 沒有剪影，直接顯示照片
    if (!_imagesLoaded || _stencilImage == null || _capturedImage == null) {
      Widget photoWidget = Image.memory(
        state.capturedImage!,
        fit: BoxFit.cover,
      );
      
      if (state.filterType != FilterType.none) {
        photoWidget = ColorFiltered(
          colorFilter: ColorFilter.matrix(_getFilterMatrix(state.filterType)),
          child: photoWidget,
        );
      }
      return photoWidget;
    }

    // 使用 CustomPaint 實現剪影遮罩
    return CustomPaint(
      painter: _CatMaskPainter(
        stencilImage: _stencilImage!,
        capturedImage: _capturedImage!,
        filterType: state.filterType,
      ),
      size: Size.infinite,
    );
  }

  List<double> _getFilterMatrix(FilterType type) {
    switch (type) {
      case FilterType.none:
        return [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
      case FilterType.blackAndWhite:
        return [0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0.2126, 0.7152, 0.0722, 0, 0, 0, 0, 0, 1, 0];
      case FilterType.warm:
        return [1.2, 0, 0, 0, 0, 0, 1.1, 0, 0, 0, 0, 0, 0.9, 0, 0, 0, 0, 0, 1, 0];
      case FilterType.cool:
        return [0.9, 0, 0, 0, 0, 0, 1.0, 0, 0, 0, 0, 0, 1.2, 0, 0, 0, 0, 0, 1, 0];
      case FilterType.vintage:
        return [0.9, 0.1, 0.1, 0, 10, 0.1, 0.8, 0.1, 0, 10, 0.1, 0.1, 0.6, 0, 20, 0, 0, 0, 1, 0];
      case FilterType.HDR:
        return [1.3, 0, 0, 0, -20, 0, 1.3, 0, 0, -20, 0, 0, 1.3, 0, -20, 0, 0, 0, 1, 0];
    }
  }
}

/// 貓咪形狀遮罩畫家
class _CatMaskPainter extends CustomPainter {
  final ui.Image stencilImage;
  final ui.Image capturedImage;
  final FilterType filterType;

  _CatMaskPainter({
    required this.stencilImage,
    required this.capturedImage,
    required this.filterType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 計算照片的縮放和偏移（保持比例，填滿區域）
    final photoScaleX = size.width / capturedImage.width;
    final photoScaleY = size.height / capturedImage.height;
    final photoScale = photoScaleX > photoScaleY ? photoScaleX : photoScaleY; // 用較大的確保填滿
    final photoOffsetX = (size.width - capturedImage.width * photoScale) / 2;
    final photoOffsetY = (size.height - capturedImage.height * photoScale) / 2;

    // 計算剪影的縮放和偏移
    final stencilScaleX = size.width / stencilImage.width;
    final stencilScaleY = size.height / stencilImage.height;
    final stencilScale = stencilScaleX > stencilScaleY ? stencilScaleX : stencilScaleY;
    final stencilOffsetX = (size.width - stencilImage.width * stencilScale) / 2;
    final stencilOffsetY = (size.height - stencilImage.height * stencilScale) / 2;

    // 使用 saveLayer 來正確應用混合模式
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 繪製照片
    canvas.save();
    canvas.translate(photoOffsetX, photoOffsetY);
    canvas.scale(photoScale);
    canvas.drawImage(capturedImage, Offset.zero, Paint());
    canvas.restore();

    // 繪製剪影（使用 dstIn 只保留照片在剪影有內容的區域）
    canvas.save();
    canvas.translate(stencilOffsetX, stencilOffsetY);
    canvas.scale(stencilScale);
    
    final maskPaint = Paint()
      ..blendMode = BlendMode.dstIn
      ..filterQuality = FilterQuality.high;
    
    canvas.drawImage(stencilImage, Offset.zero, maskPaint);
    canvas.restore();

    canvas.restore(); // 結束 saveLayer
  }

  @override
  bool shouldRepaint(covariant _CatMaskPainter oldDelegate) {
    return oldDelegate.stencilImage != stencilImage ||
        oldDelegate.capturedImage != capturedImage ||
        oldDelegate.filterType != filterType;
  }
}
