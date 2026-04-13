import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/stencil_model.dart';
import '../../../../providers/editor_provider.dart';
import '../../../../providers/stencil_provider.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentStencil();
    });
  }

  Future<void> _loadStencilFromModel(StencilModel model) async {
    if (_isLoading) return;
    _isLoading = true;
    
    try {
      debugPrint('Loading stencil: ${model.assetPath}');
      final data = await DefaultAssetBundle.of(context).load(model.assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      debugPrint('Stencil loaded: ${frame.image.width}x${frame.image.height}');
      
      if (mounted) {
        setState(() => _stencilImage = frame.image);
      }
    } catch (e) {
      debugPrint('Failed to load stencil: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _loadCurrentStencil() async {
    final selectedStencil = ref.read(selectedStencilProvider);
    debugPrint('_loadCurrentStencil: $selectedStencil');
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
    final selectedStencil = ref.watch(selectedStencilProvider);

    // 當剪影變化時，重新載入
    ref.listen<StencilModel?>(selectedStencilProvider, (previous, next) {
      debugPrint('Stencil changed: $previous -> $next');
      if (next != null && next.id != previous?.id) {
        _loadStencilFromModel(next);
      }
    });

    // 如果沒有選擇剪影，不顯示
    if (selectedStencil == null) {
      return const SizedBox.shrink();
    }

    // 如果剪影還沒載入，嘗試載入
    if (_stencilImage == null && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadStencilFromModel(selectedStencil);
      });
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_stencilImage == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Positioned.fill(
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onDoubleTap: _onDoubleTap,
        child: _buildOverlay(),
      ),
    );
  }

  Widget _buildOverlay() {
    const baseSize = 300.0;
    final stencilSize = baseSize * _scale;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final left = (screenWidth - stencilSize) / 2 + _offset.dx;
    final top = (screenHeight - stencilSize) / 2 + _offset.dy;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 半透明黑色背景
        Container(color: Colors.black.withOpacity(0.3)),

        // 用 CustomPaint 繪製剪影遮罩
        Positioned(
          left: left,
          top: top,
          child: Transform.rotate(
            angle: _rotation,
            child: Transform.scale(
              scale: _isFlipped ? -_scale : _scale,
              alignment: Alignment.center,
              child: CustomPaint(
                size: Size(stencilSize, stencilSize),
                painter: _StencilPainter(_stencilImage!),
              ),
            ),
          ),
        ),

        // 白色邊框
        Positioned(
          left: left,
          top: top,
          child: Container(
            width: stencilSize,
            height: stencilSize,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
      ],
    );
  }
}

/// 剪影畫家
class _StencilPainter extends CustomPainter {
  final ui.Image image;

  _StencilPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    // 使用 saveLayer 來應用混合模式
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 先填充白色（會被保留的部分）
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // 計算縮放
    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    final offsetX = (size.width - image.width * scale) / 2;
    final offsetY = (size.height - image.height * scale) / 2;

    // 繪製剪影（使用 dstOut 混合模式：剪影中黑色的部分會移除白色）
    canvas.saveLayer(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..blendMode = BlendMode.dstOut,
    );

    canvas.drawImage(
      image,
      Offset(offsetX, offsetY),
      Paint()..filterQuality = FilterQuality.high,
    );

    canvas.restore(); // 結束 dstOut
    canvas.restore(); // 結束 saveLayer
  }

  @override
  bool shouldRepaint(covariant _StencilPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
