import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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

  Future<void> _saveImage() async {
    try {
      final state = ref.read(editorStateProvider);
      if (state.capturedImage == null) return;

      // 獲取臨時目錄
      final tempDir = await getTemporaryDirectory();
      final fileName = 'fillmeow_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${tempDir.path}/$fileName';

      // 保存圖片（實際項目中需要應用合成）
      final file = File(filePath);
      await file.writeAsBytes(state.capturedImage!);

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
            onPressed: _saveImage,
            child: const Text(
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
