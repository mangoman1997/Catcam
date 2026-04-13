import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/editor_state.dart';
import '../../../../providers/editor_provider.dart';
import '../../../../core/constants/app_colors.dart';

/// 合成預覽組件 - 只保留貓咪形狀內的照片
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
      final data = await DefaultAssetBundle.of(context)
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

    // 沒有照片，顯示背景色
    if (editorState.capturedImage == null) {
      return Container(color: AppColors.cameraBackground);
    }

    // 沒有剪影，直接顯示照片
    if (!_imagesLoaded || _stencilImage == null || _capturedImage == null) {
      Widget photoWidget = Image.memory(
        editorState.capturedImage!,
        fit: BoxFit.cover,
      );
      
      if (editorState.filterType != FilterType.none) {
        photoWidget = ColorFiltered(
          colorFilter: ColorFilter.matrix(_getFilterMatrix(editorState.filterType)),
          child: photoWidget,
        );
      }
      return photoWidget;
    }

    // 有剪影：使用 ShaderMask 只顯示貓咪形狀內的照片
    return _buildCatShapedPreview();
  }

  Widget _buildCatShapedPreview() {
    final editorState = ref.watch(editorStateProvider);
    
    // 計算縮放
    final stencilSize = 300.0 * editorState.stencilScale;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final left = (screenWidth - stencilSize) / 2 + editorState.stencilOffset.dx;
    final top = (screenHeight - stencilSize) / 2 + editorState.stencilOffset.dy;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 底層：透明背景
        Container(color: Colors.transparent),

        // 上層：只在剪影形狀內顯示照片
        // 使用 ShaderMask + ImageShader
        Positioned(
          left: left,
          top: top,
          child: Transform.rotate(
            angle: editorState.stencilRotation,
            child: Transform.scale(
              scale: editorState.isFlippedHorizontally ? -editorState.stencilScale : editorState.stencilScale,
              alignment: Alignment.center,
              child: ShaderMask(
                shaderCallback: (bounds) {
                  // 建立圖片著色器
                  // stencil 的黑色區域 = 高透明度 = 顯示
                  // stencil 的透明區域 = 低透明度 = 隱藏
                  final matrix = Matrix4.identity();
                  matrix.scale(
                    bounds.width / _stencilImage!.width,
                    bounds.height / _stencilImage!.height,
                  );
                  return ImageShader(
                    _stencilImage!,
                    TileMode.clamp,
                    TileMode.clamp,
                    matrix.storage,
                  );
                },
                blendMode: BlendMode.dstIn,
                child: Image.memory(
                  widget.state.capturedImage!,
                  fit: BoxFit.cover,
                  width: stencilSize,
                  height: stencilSize,
                ),
              ),
            ),
          ),
        ),
      ],
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
