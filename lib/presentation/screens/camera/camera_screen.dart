import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/camera_provider.dart';
import '../../../providers/editor_provider.dart';
import '../../../providers/stencil_provider.dart';
import '../../../presentation/widgets/stencil_picker_sheet.dart';
import 'widgets/camera_preview_widget.dart';
import 'widgets/stencil_overlay_widget.dart';
import 'widgets/camera_toolbar.dart';
import 'widgets/capture_button.dart';

/// 主相機頁面
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 不要在這裡 dispose 相機！否則打開底部面板會導致相機失效
    // 相機應該在 dispose() 方法中統一管理
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;

    final controller = ref.read(cameraControllerProvider).valueOrNull;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final timerSeconds = ref.read(timerSecondsProvider);
      if (timerSeconds > 0) {
        for (int i = timerSeconds; i > 0; i--) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$i...'),
              duration: const Duration(seconds: 1),
              backgroundColor: Colors.black87,
            ),
          );
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      final xFile = await controller.takePicture();
      final bytes = await xFile.readAsBytes();

      // 保存當前選中的剪影
      final selectedStencil = ref.read(selectedStencilProvider);
      
      // 設置圖片（同時保留剪影）
      ref.read(editorStateProvider.notifier).setCapturedImage(bytes);
      
      // 如果有選中剪影，也設置到 editorState
      if (selectedStencil != null) {
        ref.read(editorStateProvider.notifier).selectStencil(selectedStencil);
      }

      if (!mounted) return;

      context.push('/editor');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('拍攝失敗: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCapturing = false);
      }
    }
  }

  void _switchCamera() async {
    final controller = ref.read(cameraControllerProvider).valueOrNull;
    if (controller != null) {
      await controller.dispose();
    }

    final currentIndex = ref.read(currentCameraIndexProvider);
    final cameras = await ref.read(availableCamerasProvider.future);
    
    if (cameras.length > 1) {
      ref.read(currentCameraIndexProvider.notifier).state =
          (currentIndex + 1) % cameras.length;
    }
  }

  void _toggleFlash() async {
    final controller = ref.read(cameraControllerProvider).valueOrNull;
    if (controller == null) return;

    final currentMode = ref.read(flashModeProvider);
    FlashMode newMode;

    switch (currentMode) {
      case FlashMode.off:
        newMode = FlashMode.auto;
        break;
      case FlashMode.auto:
        newMode = FlashMode.always;
        break;
      case FlashMode.always:
        newMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        newMode = FlashMode.off;
        break;
    }

    try {
      await controller.setFlashMode(newMode);
      ref.read(flashModeProvider.notifier).state = newMode;
    } catch (e) {
      // ignore
    }
  }

  void _toggleGrid() {
    ref.read(showGridProvider.notifier).state =
        !ref.read(showGridProvider);
  }

  void _openStencilPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const StencilPickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controllerAsync = ref.watch(cameraControllerProvider);
    final showGrid = ref.watch(showGridProvider);

    return Scaffold(
      backgroundColor: AppColors.cameraBackground,
      body: Stack(
        fit: StackFit.expand,
        children: [
          controllerAsync.when(
            data: (controller) {
              if (controller == null) {
                return const Center(
                  child: Text(
                    '無法訪問相機',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }
              return CameraPreviewWidget(
                controller: controller,
                showGrid: showGrid,
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
            error: (error, stack) => Center(
              child: Text(
                '相機錯誤: $error',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),

          const StencilOverlayWidget(),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: CameraToolbar(
                onSwitchCamera: _switchCamera,
                onToggleFlash: _toggleFlash,
                onToggleGrid: _toggleGrid,
                onOpenSettings: () => context.push('/settings'),
                showGrid: showGrid,
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: AppDimensions.bottomBarHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingLg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildThumbnail(),
                    CaptureButton(
                      onTap: _captureImage,
                      isCapturing: _isCapturing,
                    ),
                    _buildSelectCatButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    final lastImage = ref.watch(lastCapturedImageProvider);

    return GestureDetector(
      onTap: lastImage != null ? () => context.push('/editor') : null,
      child: Container(
        width: AppDimensions.thumbnailSize,
        height: AppDimensions.thumbnailSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: lastImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm - 2),
                child: Image.file(
                  File(lastImage),
                  fit: BoxFit.cover,
                ),
              )
            : const Icon(
                Icons.image,
                color: Colors.white54,
                size: 24,
              ),
      ),
    );
  }

  Widget _buildSelectCatButton() {
    return GestureDetector(
      onTap: _openStencilPicker,
      child: Container(
        width: AppDimensions.thumbnailSize,
        height: AppDimensions.thumbnailSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          color: AppColors.surface,
        ),
        child: const Icon(
          Icons.pets,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }
}
