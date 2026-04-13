import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../providers/camera_provider.dart';

/// 相機工具列組件
class CameraToolbar extends ConsumerWidget {
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleFlash;
  final VoidCallback onToggleGrid;
  final VoidCallback onOpenSettings;
  final bool showGrid;

  const CameraToolbar({
    super.key,
    required this.onSwitchCamera,
    required this.onToggleFlash,
    required this.onToggleGrid,
    required this.onOpenSettings,
    required this.showGrid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flashMode = ref.watch(flashModeProvider);

    return Container(
      height: AppDimensions.toolbarHeight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 左側按鈕
          Row(
            children: [
              _ToolbarButton(
                icon: _getFlashIcon(flashMode),
                onTap: onToggleFlash,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              _ToolbarButton(
                icon: Icon(
                  Icons.grid_on,
                  color: showGrid ? AppColors.primary : Colors.white,
                ),
                onTap: onToggleGrid,
              ),
            ],
          ),

          // 右側按鈕
          Row(
            children: [
              _ToolbarButton(
                icon: const Icon(Icons.flip_camera_ios),
                onTap: onSwitchCamera,
              ),
              const SizedBox(width: AppDimensions.spacingSm),
              _ToolbarButton(
                icon: const Icon(Icons.settings),
                onTap: onOpenSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFlashIcon(FlashMode mode) {
    switch (mode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppDimensions.toolButtonSize,
        height: AppDimensions.toolButtonSize,
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        child: icon,
      ),
    );
  }
}
