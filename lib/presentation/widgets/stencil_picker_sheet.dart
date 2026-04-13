import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/stencil_model.dart';
import '../../providers/stencil_provider.dart';

/// 剪影選擇底部彈出面板
class StencilPickerSheet extends ConsumerWidget {
  const StencilPickerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final stencils = ref.watch(stencilListProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.sheetRadius),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppDimensions.spacingSm),
            width: AppDimensions.sheetHandleWidth,
            height: AppDimensions.sheetHandleHeight,
            decoration: BoxDecoration(
              color: AppColors.outlineLight,
              borderRadius: BorderRadius.circular(AppDimensions.sheetHandleHeight / 2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  '選擇剪影',
                  style: AppTypography.h4,
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Category Tabs
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingMd,
              ),
              itemCount: StencilCategory.values.length,
              itemBuilder: (context, index) {
                final category = StencilCategory.values[index];
                final isSelected = category == selectedCategory;

                return GestureDetector(
                  onTap: () => ref
                      .read(selectedCategoryProvider.notifier)
                      .state = category,
                  child: Container(
                    margin: const EdgeInsets.only(right: AppDimensions.spacingSm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingMd,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category.label,
                      style: AppTypography.bodySmall.copyWith(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: AppDimensions.spacingMd),

          // Stencil Grid
          Expanded(
            child: stencils.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pets,
                          size: 64,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),
                        Text(
                          '這個分類還沒有剪影',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(AppDimensions.spacingMd),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: AppDimensions.stencilGridSpacing,
                      mainAxisSpacing: AppDimensions.stencilGridSpacing,
                      childAspectRatio: 1,
                    ),
                    itemCount: stencils.length,
                    itemBuilder: (context, index) {
                      final stencil = stencils[index];
                      return _StencilGridItem(
                        stencil: stencil,
                        isSelected: ref.watch(selectedStencilProvider) == stencil,
                        onTap: () {
                          // 同步設置到 both providers
                          ref.read(selectedStencilProvider.notifier).state = stencil;
                          ref.read(editorStateProvider.notifier).selectStencil(stencil);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StencilGridItem extends StatelessWidget {
  final StencilModel stencil;
  final bool isSelected;
  final VoidCallback onTap;

  const _StencilGridItem({
    required this.stencil,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 剪影預覽 - 顯示真實圖片
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                child: _StencilImage(assetPath: stencil.assetPath),
              ),
            ),

            // 名稱
            Positioned(
              bottom: AppDimensions.spacingXs,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  stencil.name,
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 載入並顯示剪影圖片
class _StencilImage extends StatefulWidget {
  final String assetPath;

  const _StencilImage({required this.assetPath});

  @override
  State<_StencilImage> createState() => _StencilImageState();
}

class _StencilImageState extends State<_StencilImage> {
  ui.Image? _image;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final data = await DefaultAssetBundle.of(context).load(widget.assetPath);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      
      if (mounted) {
        setState(() {
          _image = frame.image;
          _loaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load stencil image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _image == null) {
      // 載入中顯示 placeholder
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.outlineLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return CustomPaint(
      painter: _StencilPainter(_image!),
      size: const Size(80, 80),
    );
  }
}

class _StencilPainter extends CustomPainter {
  final ui.Image image;

  _StencilPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    // 計算縮放比例，使圖片完整顯示在区域内
    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    final offsetX = (size.width - image.width * scale) / 2;
    final offsetY = (size.height - image.height * scale) / 2;

    canvas.save();
    canvas.translate(offsetX, offsetY);
    canvas.scale(scale);
    canvas.drawImage(image, Offset.zero, Paint());
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StencilPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
