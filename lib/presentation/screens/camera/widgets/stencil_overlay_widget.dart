import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/stencil_model.dart';
import '../../../../providers/editor_provider.dart';
import '../../../../providers/stencil_provider.dart';

/// 剪影疊加組件 - 即時AR效果
/// 在相機預覽上顯示剪影作為拍照引導
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentStencil();
    });
  }

  Future<void> _loadStencilFromModel(StencilModel model) async {
    debugPrint('Loading stencil: ${model.assetPath}');
    try {
      final data = await DefaultAssetBundle.of(context).load(model.assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      debugPrint('Stencil loaded: ${frame.image.width}x${frame.image.height}');
      if (mounted) {
        setState(() => _stencilImage = frame.image);
      }
    } catch (e) {
      debugPrint('ERROR loading stencil: $e');
      if (mounted) setState(() => _stencilImage = null);
    }
  }

  Future<void> _loadCurrentStencil() async {
    final selectedStencil = ref.read(selectedStencilProvider);
    if (selectedStencil != null) {
      await _loadStencilFromModel(selectedStencil);
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
    setState(() => _isFlipped = !_isFlipped);
    ref.read(editorStateProvider.notifier).flipStencil();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<StencilModel?>(selectedStencilProvider, (previous, next) {
      if (next != null) {
        _loadStencilFromModel(next);
      } else {
        if (mounted) setState(() => _stencilImage = null);
      }
    });

    final selectedStencil = ref.watch(selectedStencilProvider);
    if (selectedStencil == null || _stencilImage == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onDoubleTap: _onDoubleTap,
        child: _buildStencilGuide(),
      ),
    );
  }

  Widget _buildStencilGuide() {
    const baseSize = 300.0;
    final stencilSize = baseSize * _scale;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final left = (screenWidth - stencilSize) / 2 + _offset.dx;
    final top = (screenHeight - stencilSize) / 2 + _offset.dy;

    // 使用 CustomPaint 繪製剪影圖片
    return Stack(
      fit: StackFit.expand,
      children: [
        // 半透明黑色背景（非剪影區域）
        // 這會擋住相機，讓剪影區域更明顯
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),

        // 用 dstOut 混合模式在剪影區域 "挖洞" 顯示相機
        Positioned(
          left: left,
          top: top,
          child: ShaderMask(
            shaderCallback: (bounds) {
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
            blendMode: BlendMode.dstOut,
            child: Transform.rotate(
              angle: _rotation,
              child: Transform.scale(
                scale: _isFlipped ? -_scale : _scale,
                alignment: Alignment.center,
                child: Container(
                  width: stencilSize,
                  height: stencilSize,
                  color: Colors.white, // 白色會被移除，露出相機
                ),
              ),
            ),
          ),
        ),

        // 白色邊框
        Positioned(
          left: left,
          top: top,
          child: Transform.rotate(
            angle: _rotation,
            child: Transform.scale(
              scale: _isFlipped ? -1.0 : 1.0,
              alignment: Alignment.center,
              child: Container(
                width: stencilSize,
                height: stencilSize,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
