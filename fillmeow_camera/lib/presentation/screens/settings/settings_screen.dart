import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';

/// 設定頁面
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '設定',
          style: AppTypography.h4,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.spacingMd),
        children: [
          // 基本設定
          _SettingsSection(
            title: '基本設定',
            children: [
              _SettingsTile(
                icon: Icons.language,
                title: '語言',
                subtitle: '繁體中文',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.dark_mode,
                title: '深色模式',
                subtitle: '關',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingMd),

          // 拍攝設定
          _SettingsSection(
            title: '拍攝設定',
            children: [
              _SettingsTile(
                icon: Icons.grid_on,
                title: '預設顯示網格',
                subtitle: '關',
                trailing: Switch(
                  value: false,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.timer,
                title: '預設定時器',
                subtitle: '關',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.flash_on,
                title: '預設閃光燈',
                subtitle: '關',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingMd),

          // 儲存與分享
          _SettingsSection(
            title: '儲存與分享',
            children: [
              _SettingsTile(
                icon: Icons.save,
                title: '自動保存到相簿',
                subtitle: '開',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.watermark,
                title: '添加水印',
                subtitle: '開',
                trailing: Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: AppColors.primary,
                ),
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingMd),

          // 進階設定
          _SettingsSection(
            title: '進階設定',
            children: [
              _SettingsTile(
                icon: Icons.high_quality,
                title: '圖片品質',
                subtitle: '高',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.videocam,
                title: '影片解析度',
                subtitle: '1080p',
                onTap: () {},
              ),
            ],
          ),

          const SizedBox(height: AppDimensions.spacingMd),

          // 關於
          _SettingsSection(
            title: '關於',
            children: [
              _SettingsTile(
                icon: Icons.info,
                title: '版本',
                subtitle: '1.0.0',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.description,
                title: '隱私政策',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.help,
                title: '使用說明',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.star,
                title: '評分支持',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppDimensions.spacingSm,
            bottom: AppDimensions.spacingSm,
          ),
          child: Text(
            title,
            style: AppTypography.label.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primary,
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: AppTypography.bodySmall,
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right,
                  color: AppColors.textSecondary,
                )
              : null),
      onTap: onTap,
    );
  }
}
