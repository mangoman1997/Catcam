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
                const SizedBox(width: 48), // 佔位
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
                          ref
                              .read(selectedStencilProvider.notifier)
                              .state = stencil;
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
            // 剪影預覽
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.spacingMd),
                child: CustomPaint(
                  painter: _CatStencilPainter(),
                ),
              ),
            ),

            // 名稱
            Positioned(
              bottom: AppDimensions.spacingXs,
              left: 0,
              right: 0,
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

            // Premium 標記
            if (stencil.isPremium)
              Positioned(
                top: AppDimensions.spacingXs,
                right: AppDimensions.spacingXs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CatStencilPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textSecondary.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final center = Offset(size.width / 2, size.height / 2);

    // 頭部
    canvas.drawCircle(
      Offset(center.dx, center.dy - size.height * 0.15),
      size.width * 0.3,
      paint,
    );

    // 身體
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + size.height * 0.2),
        width: size.width * 0.7,
        height: size.height * 0.5,
      ),
      paint,
    );

    // 左耳
    final leftEarPath = Path()
      ..moveTo(center.dx - size.width * 0.25, center.dy - size.height * 0.3)
      ..lineTo(center.dx - size.width * 0.3, center.dy - size.height * 0.55)
      ..lineTo(center.dx - size.width * 0.1, center.dy - size.height * 0.35)
      ..close();
    canvas.drawPath(leftEarPath, paint);

    // 右耳
    final rightEarPath = Path()
      ..moveTo(center.dx + size.width * 0.25, center.dy - size.height * 0.3)
      ..lineTo(center.dx + size.width * 0.3, center.dy - size.height * 0.55)
      ..lineTo(center.dx + size.width * 0.1, center.dy - size.height * 0.35)
      ..close();
    canvas.drawPath(rightEarPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
