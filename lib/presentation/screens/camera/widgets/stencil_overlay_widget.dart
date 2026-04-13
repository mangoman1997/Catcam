import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/editor_provider.dart';
import '../../../../providers/stencil_provider.dart';
import '../../../../core/constants/app_colors.dart';

/// 剪影疊加組件 - 即時AR效果
/// 只在貓咪形狀內顯示相機畫面，其他區域被遮罩
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
            ? _buildARMaskOverlay()
            : Container(color: Colors.transparent),
      ),
    );
  }

  /// 構建AR遮罩層
  /// 黑色（貓咪）= 透明（顯示相機）
  /// 透明 = 遮罩色（擋住相機）
  Widget _buildARMaskOverlay() {
    final stencilSize = 300.0 * _scale;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final left = screenWidth / 2 - stencilSize / 2 + _offset.dx;
    final top = screenHeight / 2 - stencilSize / 2 + _offset.dy;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 底層：遮罩色（擋住整個畫面）
        Container(color: AppColors.cameraBackground),

        // 上層：只在剪影形狀內"移除"遮罩（讓相機畫面通過）
        // 使用 BlendMode.dstOut：shader 有內容的地方會從目標中移除
        // 黑色（貓咪）= 有內容 = 移除遮罩 = 顯示相機
        // 透明 = 無內容 = 保留遮罩 = 擋住相機
        Transform.translate(
          offset: Offset(left, top),
          child: Transform.rotate(
            angle: _rotation,
            child: Transform.scale(
              scale: _isFlipped ? -_scale : _scale,
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return ImageShader(
                    _stencilImage!,
                    TileMode.clamp,
                    TileMode.clamp,
                    Matrix4.identity().storage,
                  );
                },
                blendMode: BlendMode.dstOut,
                child: Container(
                  width: stencilSize,
                  height: stencilSize,
                  color: Colors.white, // 白色會被移除
                ),
              ),
            ),
          ),
        ),

        // 頂層：白色邊框提示
        Positioned(
          left: left,
          top: top,
          child: Container(
            width: stencilSize,
            height: stencilSize,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withOpacity(0.6),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
