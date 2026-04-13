import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/models/editor_state.dart';
import '../../../providers/editor_provider.dart';
import '../../../providers/stencil_provider.dart';
import 'widgets/composite_preview.dart';
import 'widgets/parameter_controls.dart';

/// 編輯預覽頁面
class EditorScreen extends ConsumerStatefulWidget {
  const EditorScreen({super.key});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  int _selectedTab = 0;
  bool _isSaving = false;

  Future<Uint8List?> _renderImageWithMask(EditorState state) async {
    if (state.capturedImage == null) return null;

    try {
      // 載入剪影圖
      ui.Image? stencilImage;
      if (state.selectedStencil != null) {
        final data = await DefaultAssetBundle.of(ref.context)
            .load(state.selectedStencil!.assetPath);
        final bytes = data.buffer.asUint8List();
        final codec = await ui.instantiateImageCodec(bytes);
        stencilImage = (await codec.getNextFrame()).image;
      }

      // 載入拍攝的照片
      final capturedCodec = await ui.instantiateImageCodec(state.capturedImage!);
      final capturedImage = (await capturedCodec.getNextFrame()).image;

      // 創建輸出圖片
      final size = Size(
        capturedImage.width.toDouble(),
        capturedImage.height.toDouble(),
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      // 繪製背景色
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = AppColors.cameraBackground,
      );

      // 如果有剪影，應用遮罩
      if (stencilImage != null) {
        // 計算縮放比例
        final stencilScaleX = size.width / stencilImage.width;
        final stencilScaleY = size.height / stencilImage.height;
        final stencilScale = stencilScaleX > stencilScaleY ? stencilScaleX : stencilScaleY;
        final stencilOffsetX = (size.width - stencilImage.width * stencilScale) / 2;
        final stencilOffsetY = (size.height - stencilImage.height * stencilScale) / 2;

        // 使用 saveLayer 應用混合模式
        canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

        // 繪製照片
        final photoScaleX = size.width / capturedImage.width;
        final photoScaleY = size.height / capturedImage.height;
        final photoScale = photoScaleX > photoScaleY ? photoScaleX : photoScaleY;
        final photoOffsetX = (size.width - capturedImage.width * photoScale) / 2;
        final photoOffsetY = (size.height - capturedImage.height * photoScale) / 2;

        canvas.save();
        canvas.translate(photoOffsetX, photoOffsetY);
        canvas.scale(photoScale);
        canvas.drawImage(capturedImage, Offset.zero, Paint());
        canvas.restore();

        // 應用剪影遮罩
        canvas.save();
        canvas.translate(stencilOffsetX, stencilOffsetY);
        canvas.scale(stencilScale);
        
        final maskPaint = Paint()
          ..blendMode = BlendMode.dstIn
          ..filterQuality = FilterQuality.high;
        
        canvas.drawImage(stencilImage, Offset.zero, maskPaint);
        canvas.restore();

        canvas.restore(); // 結束 saveLayer
      } else {
        // 沒有剪影，直接繪製照片
        final photoScaleX = size.width / capturedImage.width;
        final photoScaleY = size.height / capturedImage.height;
        final photoScale = photoScaleX > photoScaleY ? photoScaleX : photoScaleY;
        final photoOffsetX = (size.width - capturedImage.width * photoScale) / 2;
        final photoOffsetY = (size.height - capturedImage.height * photoScale) / 2;

        canvas.save();
        canvas.translate(photoOffsetX, photoOffsetY);
        canvas.scale(photoScale);
        canvas.drawImage(capturedImage, Offset.zero, Paint());
        canvas.restore();
      }

      // 編碼為 PNG
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to render image: $e');
      return null;
    }
  }

  Future<void> _saveImage() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final state = ref.read(editorStateProvider);
      if (state.capturedImage == null) return;

      // 渲染帶有剪影效果的圖片
      final imageBytes = await _renderImageWithMask(state);

      if (imageBytes == null) {
        throw Exception('渲染圖片失敗');
      }

      // 獲取臨時目錄
      final tempDir = await getTemporaryDirectory();
      final fileName = 'fillmeow_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';

      // 保存圖片
      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      if (!mounted) return;

      // 顯示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('圖片已保存'),
          backgroundColor: AppColors.success,
          action: SnackBarAction(
            label: '分享',
            textColor: Colors.white,
            onPressed: () => _shareImage(filePath),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('保存失敗: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareImage(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: '用填貓相機做了一張創意照片！ 🐱 #填貓相機 #CatFillWorld',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('分享失敗: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(editorStateProvider.notifier).reset();
            context.pop();
          },
        ),
        title: const Text(
          '編輯',
          style: AppTypography.h4,
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveImage,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '保存',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 預覽區域
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(AppDimensions.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                child: editorState.capturedImage != null
                    ? CompositePreview(state: editorState)
                    : const Center(
                        child: Text('沒有拍攝圖片'),
                      ),
              ),
            ),
          ),

          // 功能Tab
          Container(
            height: AppDimensions.tabBarHeight,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(
                top: BorderSide(color: AppColors.outlineLight),
              ),
            ),
            child: Row(
              children: [
                _TabButton(
                  label: '輪廓線',
                  icon: Icons.format_paint,
                  isSelected: _selectedTab == 0,
                  onTap: () => setState(() => _selectedTab = 0),
                ),
                _TabButton(
                  label: '填滿',
                  icon: Icons.blur_on,
                  isSelected: _selectedTab == 1,
                  onTap: () => setState(() => _selectedTab = 1),
                ),
                _TabButton(
                  label: '濾鏡',
                  icon: Icons.filter,
                  isSelected: _selectedTab == 2,
                  onTap: () => setState(() => _selectedTab = 2),
                ),
                _TabButton(
                  label: '文字',
                  icon: Icons.text_fields,
                  isSelected: _selectedTab == 3,
                  onTap: () => setState(() => _selectedTab = 3),
                ),
              ],
            ),
          ),

          // 參數控制區域
          Expanded(
            flex: 2,
            child: ParameterControls(
              selectedTab: _selectedTab,
              state: editorState,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
