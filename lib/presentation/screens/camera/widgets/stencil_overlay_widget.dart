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

    // 監聽剪影變化
    ref.listen<StencilModel?>(selectedStencilProvider, (previous, next) {
      debugPrint('Stencil changed: $previous -> $next');
      if (next != null && next.id != previous?.id) {
        _loadStencilFromModel(next);
      }
    });

    if (selectedStencil == null) {
      return const SizedBox.shrink();
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
        // 直接用 CustomPaint 繪製剪影圖片
        Positioned(
          left: left,
          top: top,
          child: Transform.rotate(
            angle: _rotation,
            child: Transform.scale(
              scale: _isFlipped ? -_scale : _scale,
              alignment: Alignment.center,
              child: Opacity(
                opacity: 0.6, // 半透明
                child: CustomPaint(
                  size: Size(stencilSize, stencilSize),
                  painter: _SimpleStencilPainter(_stencilImage!),
                ),
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

/// 簡單的剪影畫家 - 直接繪製圖片
class _SimpleStencilPainter extends CustomPainter {
  final ui.Image image;

  _SimpleStencilPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    // 計算縮放比例，使圖片完整填充目標區域
    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    // 居中偏移
    final offsetX = (size.width - image.width * scale) / 2;
    final offsetY = (size.height - image.height * scale) / 2;

    // 保存狀態
    canvas.save();

    // 移動到正確位置
    canvas.translate(offsetX, offsetY);
    
    // 縮放
    canvas.scale(scale);

    // 繪製圖片
    canvas.drawImage(image, Offset.zero, Paint());

    // 恢復狀態
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SimpleStencilPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
