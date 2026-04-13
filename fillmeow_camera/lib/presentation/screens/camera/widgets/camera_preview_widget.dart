import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// 相機預覽組件
class CameraPreviewWidget extends StatelessWidget {
  final CameraController controller;
  final bool showGrid;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    this.showGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 相機預覽
        CameraPreview(controller),
        
        // 網格輔助線
        if (showGrid)
          IgnorePointer(
            child: GridOverlay(),
          ),
      ],
    );
  }
}

/// 網格覆蓋層
class GridOverlay extends StatelessWidget {
  const GridOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      child: Container(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 0.5;

    // 垂直線
    final cellWidth = size.width / 3;
    for (int i = 1; i < 3; i++) {
      final x = cellWidth * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // 水平線
    final cellHeight = size.height / 3;
    for (int i = 1; i < 3; i++) {
      final y = cellHeight * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
