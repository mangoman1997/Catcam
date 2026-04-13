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

  /// 構建圖片層
  Widget _buildImageLayer(EditorState state) {
    Widget imageWidget = Image.memory(
      state.capturedImage!,
      fit: BoxFit.cover,
    );

    // 應用濾鏡
    if (state.filterType != FilterType.none) {
      imageWidget = ColorFiltered(
        colorFilter: ColorFilter.matrix(_getFilterMatrix(state.filterType)),
        child: imageWidget,
      );
    }

    // 如果有剪影，應用剪影遮罩
    if (_imageLoaded && _stencilImage != null && state.selectedStencil != null) {
      // dstIn: 只保留目標（照片）在來源（剪影）有內容的區域
      // 黑色（貓咪）= 有內容 → 顯示照片
      // 透明 = 無內容 → 隱藏照片
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
        child: ColorFiltered(
          colorFilter: ColorFilter.matrix(_getFilterMatrix(state.filterType)),
          child: Image.memory(
            state.capturedImage!,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return imageWidget;
  }

  /// 獲取濾鏡矩陣
  List<double> _getFilterMatrix(FilterType type) {
    switch (type) {
      case FilterType.none:
        return [
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FilterType.blackAndWhite:
        return [
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FilterType.warm:
        return [
          1.2, 0, 0, 0, 0,
          0, 1.1, 0, 0, 0,
          0, 0, 0.9, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FilterType.cool:
        return [
          0.9, 0, 0, 0, 0,
          0, 1.0, 0, 0, 0,
          0, 0, 1.2, 0, 0,
          0, 0, 0, 1, 0,
        ];
      case FilterType.vintage:
        return [
          0.9, 0.1, 0.1, 0, 10,
          0.1, 0.8, 0.1, 0, 10,
          0.1, 0.1, 0.6, 0, 20,
          0, 0, 0, 1, 0,
        ];
      case FilterType.HDR:
        return [
          1.3, 0, 0, 0, -20,
          0, 1.3, 0, 0, -20,
          0, 0, 1.3, 0, -20,
          0, 0, 0, 1, 0,
        ];
    }
  }
}
