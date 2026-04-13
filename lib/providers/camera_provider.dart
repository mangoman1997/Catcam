import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 可用的相機列表
final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) async {
  try {
    return await availableCameras();
  } catch (e) {
    return [];
  }
});

/// 當前相機索引
final currentCameraIndexProvider = StateProvider<int>((ref) {
  return 0;
});

/// 閃光燈模式
final flashModeProvider = StateProvider<FlashMode>((ref) {
  return FlashMode.off;
});

/// 是否顯示網格
final showGridProvider = StateProvider<bool>((ref) {
  return false;
});

/// 計時器秒數 (0 = 關閉)
final timerSecondsProvider = StateProvider<int>((ref) {
  return 0;
});

/// 相機控制器Provider
final cameraControllerProvider = FutureProvider.autoDispose<CameraController?>((ref) async {
  final cameras = await ref.watch(availableCamerasProvider.future);
  final cameraIndex = ref.watch(currentCameraIndexProvider);
  
  if (cameras.isEmpty) {
    return null;
  }
  
  final cameraIndexActual = cameraIndex % cameras.length;
  final camera = cameras[cameraIndexActual];
  
  final controller = CameraController(
    camera,
    ResolutionPreset.high,
    enableAudio: false,
    imageFormatGroup: ImageFormatGroup.jpeg,
  );
  
  await controller.initialize();
  
  // 應用當前閃光燈模式
  final flashMode = ref.read(flashModeProvider);
  try {
    await controller.setFlashMode(flashMode);
  } catch (e) {
    // 忽略閃光燈錯誤
  }
  
  return controller;
});

/// 最後拍攝的圖片
final lastCapturedImageProvider = StateProvider<String?>((ref) {
  return null;
});
