import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/stencil_model.dart';
import '../../../../providers/editor_provider.dart';
import '../../../../providers/stencil_provider.dart';
import '../../../../core/constants/app_colors.dart';

/// 剪影疊加組件 - 即時AR效果
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
    // 初始化時讀取狀態
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentStencil();
    });
  }

  Future<void> _loadStencilFromModel(StencilModel model) async {
    debugPrint('Loading stencil from model: ${model.assetPath}');

    try {
      final data = await DefaultAssetBundle.of(context).load(model.assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
      debugPrint('Stencil loaded successfully: ${frame.image.width}x${frame.image.height}');
      
      if (mounted) {
        setState(() => _stencilImage = frame.image);
      }
    } catch (e) {
      debugPrint('ERROR loading stencil: $e');
      if (mounted) {
        setState(() => _stencilImage = null);
      }
    }
  }

  Future<void> _loadCurrentStencil() async {
    final selectedStencil = ref.read(selectedStencilProvider);
    if (selectedStencil == null) {
      if (mounted && _stencilImage != null) {
        setState(() => _stencilImage = null);
      }
      return;
    }
    await _loadStencilFromModel(selectedStencil);
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
    // 監聽剪影選擇變化
    final selectedStencil = ref.watch(selectedStencilProvider);
    
    // 當剪影變化時重新載入
    ref.listen<StencilModel?>(selectedStencilProvider, (previous, next) {
      debugPrint('Stencil changed from ${previous?.name} to ${next?.name}');
      if (next != null) {
        _loadStencilFromModel(next);
      } else {
        if (mounted) setState(() => _stencilImage = null);
      }
    });

    // 如果沒有選擇剪影，不顯示任何東西
    if (selectedStencil == null) {
      return const SizedBox.shrink();
    }

    // 如果剪影還沒載入，顯示載入中
    if (_stencilImage == null) {
      return Positioned.fill(
        child: Container(
          color: Colors.transparent,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Positioned.fill(
      child: GestureDetector(
        onScaleStart: _onScaleStart,
        onScaleUpdate: _onScaleUpdate,
        onDoubleTap: _onDoubleTap,
        child: CustomPaint(
          painter: _StencilMaskPainter(
            stencilImage: _stencilImage!,
            offset: _offset,
            scale: _scale,
            rotation: _rotation,
            isFlipped: _isFlipped,
            backgroundColor: AppColors.cameraBackground,
          ),
        ),
      ),
    );
  }
}

/// 剪影遮罩畫家
class _StencilMaskPainter extends CustomPainter {
  final ui.Image stencilImage;
  final Offset offset;
  final double scale;
  final double rotation;
  final bool isFlipped;
  final Color backgroundColor;

  _StencilMaskPainter({
    required this.stencilImage,
    required this.offset,
    required this.scale,
    required this.rotation,
    required this.isFlipped,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 計算剪影位置和大小
    const baseSize = 300.0;
    final stencilSize = baseSize * scale;
    final centerX = size.width / 2 + offset.dx;
    final centerY = size.height / 2 + offset.dy;

    // 保存狀態
    canvas.save();

    // 移動到中心
    canvas.translate(centerX, centerY);

    // 應用翻轉
    if (isFlipped) {
      canvas.scale(-1.0, 1.0);
    }

    // 應用縮放
    canvas.scale(scale);

    // 應用旋轉
    canvas.rotate(rotation);

    // 移動回原點
    canvas.translate(-centerX, -centerY);

    // 繪製遮罩（覆蓋整個區域）
    final maskRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(maskRect, Paint()..color = backgroundColor);

    // 使用 saveLayer 來應用混合模式
    final stenicRect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: baseSize,
      height: baseSize,
    );

    canvas.saveLayer(stenicRect, Paint());

    // 繪製白色（會被移除的部分）
    canvas.drawRect(stenicRect, Paint()..color = Colors.white);

    // 繪製剪影（使用 dstOut 混合模式）
    // 黑色(貓咪) = 有內容 = 從目標移除 = 透明
    // 透明 = 無內容 = 保留目標 = 白色
    final maskPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..filterQuality = FilterQuality.high;

    canvas.drawImage(
      stencilImage,
      Offset(stenicRect.left, stenicRect.top),
      maskPaint,
    );

    canvas.restore(); // 結束 saveLayer

    // 繪製白色邊框
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(stenicRect, borderPaint);

    // 恢復狀態
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StencilMaskPainter oldDelegate) {
    return oldDelegate.stencilImage != stencilImage ||
        oldDelegate.offset != offset ||
        oldDelegate.scale != scale ||
        oldDelegate.rotation != rotation ||
        oldDelegate.isFlipped != isFlipped;
  }
}
