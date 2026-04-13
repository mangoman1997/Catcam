import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../data/models/editor_state.dart';
import '../../../../providers/editor_provider.dart';

/// 參數控制面板
class ParameterControls extends ConsumerWidget {
  final int selectedTab;
  final EditorState state;

  const ParameterControls({
    super.key,
    required this.selectedTab,
    required this.state,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(AppDimensions.spacingMd),
      child: switch (selectedTab) {
        0 => _OutlineControls(state: state),
        1 => _FillControls(state: state),
        2 => _FilterControls(state: state),
        3 => _TextControls(state: state),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

/// 輪廓線控制
class _OutlineControls extends ConsumerWidget {
  final EditorState state;

  const _OutlineControls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顏色選擇
        Text('輪廓顏色', style: AppTypography.label),
        const SizedBox(height: AppDimensions.spacingSm),
        Row(
          children: [
            _ColorButton(
              color: AppColors.stencilBlack,
              isSelected: state.outlineColor == AppColors.stencilBlack,
              onTap: () => ref
                  .read(editorStateProvider.notifier)
                  .updateOutlineColor(AppColors.stencilBlack),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            _ColorButton(
              color: AppColors.stencilWhite,
              isSelected: state.outlineColor == AppColors.stencilWhite,
              onTap: () => ref
                  .read(editorStateProvider.notifier)
                  .updateOutlineColor(AppColors.stencilWhite),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            _ColorButton(
              color: AppColors.stencilPink,
              isSelected: state.outlineColor == AppColors.stencilPink,
              onTap: () => ref
                  .read(editorStateProvider.notifier)
                  .updateOutlineColor(AppColors.stencilPink),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            _ColorButton(
              color: AppColors.stencilBlue,
              isSelected: state.outlineColor == AppColors.stencilBlue,
              onTap: () => ref
                  .read(editorStateProvider.notifier)
                  .updateOutlineColor(AppColors.stencilBlue),
            ),
            const Spacer(),
            _ColorButton(
              color: AppColors.stencilPurple,
              isSelected: state.outlineColor == AppColors.stencilPurple,
              onTap: () => ref
                  .read(editorStateProvider.notifier)
                  .updateOutlineColor(AppColors.stencilPurple),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingMd),

        // 粗細調整
        Text('輪廓粗細: ${state.outlineThickness.toInt()}px',
            style: AppTypography.label),
        Slider(
          value: state.outlineThickness,
          min: 1,
          max: 10,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.outlineLight,
          onChanged: (value) => ref
              .read(editorStateProvider.notifier)
              .updateOutlineThickness(value),
        ),

        // 樣式選擇
        const SizedBox(height: AppDimensions.spacingSm),
        Row(
          children: [
            _StyleButton(
              label: '實線',
              isSelected: state.outlineStyle == OutlineStyle.solid,
              onTap: () => ref
                  .read(editorStateProvider.notifier)
                  .updateOutlineStyle(OutlineStyle.solid),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            _StyleButton(
              label: '虛線',
              isSelected: state.outlineStyle == OutlineStyle.dashed,
              onTap: () => ref
                  .read(editorStateProvider.notifier)
                  .updateOutlineStyle(OutlineStyle.dashed),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            _StyleButton(
              label: '圓點',
              isSelected: state.outlineStyle == OutlineStyle.dotted,
              onTap: () => ref
                  .read(editorStateProvider.notifier)
                  .updateOutlineStyle(OutlineStyle.dotted),
            ),
          ],
        ),
      ],
    );
  }
}

/// 填滿控制
class _FillControls extends ConsumerWidget {
  final EditorState state;

  const _FillControls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('亮度: ${(state.fillBrightness * 100).toInt()}%',
            style: AppTypography.label),
        Slider(
          value: state.fillBrightness,
          min: -0.5,
          max: 0.5,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.outlineLight,
          onChanged: (value) =>
              ref.read(editorStateProvider.notifier).updateFillBrightness(value),
        ),
        Text('對比: ${(state.fillContrast * 100).toInt()}%',
            style: AppTypography.label),
        Slider(
          value: state.fillContrast,
          min: -0.5,
          max: 0.5,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.outlineLight,
          onChanged: (value) =>
              ref.read(editorStateProvider.notifier).updateFillContrast(value),
        ),
        Text('飽和度: ${(state.fillSaturation * 100).toInt()}%',
            style: AppTypography.label),
        Slider(
          value: state.fillSaturation,
          min: -1,
          max: 1,
          activeColor: AppColors.primary,
          inactiveColor: AppColors.outlineLight,
          onChanged: (value) =>
              ref.read(editorStateProvider.notifier).updateFillSaturation(value),
        ),
      ],
    );
  }
}

/// 濾鏡控制
class _FilterControls extends ConsumerWidget {
  final EditorState state;

  const _FilterControls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterThumbnail(
            label: '原圖',
            filter: FilterType.none,
            isSelected: state.filterType == FilterType.none,
            onTap: () =>
                ref.read(editorStateProvider.notifier).updateFilter(FilterType.none),
          ),
          _FilterThumbnail(
            label: '黑白',
            filter: FilterType.blackAndWhite,
            isSelected: state.filterType == FilterType.blackAndWhite,
            onTap: () => ref
                .read(editorStateProvider.notifier)
                .updateFilter(FilterType.blackAndWhite),
          ),
          _FilterThumbnail(
            label: '暖色',
            filter: FilterType.warm,
            isSelected: state.filterType == FilterType.warm,
            onTap: () =>
                ref.read(editorStateProvider.notifier).updateFilter(FilterType.warm),
          ),
          _FilterThumbnail(
            label: '冷色',
            filter: FilterType.cool,
            isSelected: state.filterType == FilterType.cool,
            onTap: () =>
                ref.read(editorStateProvider.notifier).updateFilter(FilterType.cool),
          ),
          _FilterThumbnail(
            label: '復古',
            filter: FilterType.vintage,
            isSelected: state.filterType == FilterType.vintage,
            onTap: () => ref
                .read(editorStateProvider.notifier)
                .updateFilter(FilterType.vintage),
          ),
          _FilterThumbnail(
            label: 'HDR',
            filter: FilterType.HDR,
            isSelected: state.filterType == FilterType.HDR,
            onTap: () =>
                ref.read(editorStateProvider.notifier).updateFilter(FilterType.HDR),
          ),
        ],
      ),
    );
  }
}

/// 文字控制
class _TextControls extends ConsumerStatefulWidget {
  final EditorState state;

  const _TextControls({required this.state});

  @override
  ConsumerState<_TextControls> createState() => _TextControlsState();
}

class _TextControlsState extends ConsumerState<_TextControls> {
  final _textController = TextEditingController();
  Color _selectedColor = Colors.white;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addText() {
    if (_textController.text.isNotEmpty) {
      ref.read(editorStateProvider.notifier).addText(
            _textController.text,
            const Offset(100, 200),
            _selectedColor,
          );
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _textController,
          decoration: InputDecoration(
            hintText: '輸入文字...',
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              borderSide: BorderSide.none,
            ),
          ),
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppDimensions.spacingSm),
        Row(
          children: [
            _ColorButton(
              color: Colors.white,
              isSelected: _selectedColor == Colors.white,
              onTap: () => setState(() => _selectedColor = Colors.white),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            _ColorButton(
              color: Colors.black,
              isSelected: _selectedColor == Colors.black,
              onTap: () => setState(() => _selectedColor = Colors.black),
            ),
            const SizedBox(width: AppDimensions.spacingSm),
            _ColorButton(
              color: AppColors.primary,
              isSelected: _selectedColor == AppColors.primary,
              onTap: () => setState(() => _selectedColor = AppColors.primary),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _addText,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
              ),
              child: const Text('添加'),
            ),
          ],
        ),
        if (widget.state.hasText) ...[
          const SizedBox(height: AppDimensions.spacingSm),
          TextButton(
            onPressed: () =>
                ref.read(editorStateProvider.notifier).clearText(),
            child: const Text(
              '清除文字',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

/// 顏色按鈕
class _ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorButton({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}

/// 樣式按鈕
class _StyleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StyleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingMd,
          vertical: AppDimensions.spacingSm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// 濾鏡縮圖
class _FilterThumbnail extends StatelessWidget {
  final String label;
  final FilterType filter;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterThumbnail({
    required this.label,
    required this.filter,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: AppDimensions.spacingSm),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getFilterPreviewColor(),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getFilterPreviewColor() {
    switch (filter) {
      case FilterType.none:
        return Colors.grey;
      case FilterType.blackAndWhite:
        return Colors.grey.shade700;
      case FilterType.warm:
        return Colors.orange.shade200;
      case FilterType.cool:
        return Colors.blue.shade200;
      case FilterType.vintage:
        return Colors.brown.shade300;
      case FilterType.HDR:
        return Colors.teal.shade300;
    }
  }
}
