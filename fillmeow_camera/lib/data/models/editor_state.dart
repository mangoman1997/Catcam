import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'stencil_model.dart';

/// 編輯器狀態模型
class EditorState {
  // 已拍攝的圖片
  final Uint8List? capturedImage;

  // 選中的剪影
  final StencilModel? selectedStencil;

  // 剪影變換
  final Offset stencilOffset;
  final double stencilScale;
  final double stencilRotation;
  final bool isFlippedHorizontally;

  // 輪廓線設置
  final Color outlineColor;
  final double outlineThickness;
  final OutlineStyle outlineStyle;
  final bool showOutline;

  // 填滿設置
  final double fillBrightness;
  final double fillContrast;
  final double fillSaturation;

  // 合成模式
  final CompositeMode compositeMode;

  // 濾鏡
  final FilterType filterType;

  // 文字
  final String? text;
  final Offset? textPosition;
  final Color? textColor;

  const EditorState({
    this.capturedImage,
    this.selectedStencil,
    this.stencilOffset = Offset.zero,
    this.stencilScale = 1.0,
    this.stencilRotation = 0.0,
    this.isFlippedHorizontally = false,
    this.outlineColor = const Color(0xFF000000),
    this.outlineThickness = 3.0,
    this.outlineStyle = OutlineStyle.solid,
    this.showOutline = true,
    this.fillBrightness = 0.0,
    this.fillContrast = 0.0,
    this.fillSaturation = 0.0,
    this.compositeMode = CompositeMode.fillOnly,
    this.filterType = FilterType.none,
    this.text,
    this.textPosition,
    this.textColor,
  });

  EditorState copyWith({
    Uint8List? capturedImage,
    StencilModel? selectedStencil,
    Offset? stencilOffset,
    double? stencilScale,
    double? stencilRotation,
    bool? isFlippedHorizontally,
    Color? outlineColor,
    double? outlineThickness,
    OutlineStyle? outlineStyle,
    bool? showOutline,
    double? fillBrightness,
    double? fillContrast,
    double? fillSaturation,
    CompositeMode? compositeMode,
    FilterType? filterType,
    String? text,
    Offset? textPosition,
    Color? textColor,
  }) {
    return EditorState(
      capturedImage: capturedImage ?? this.capturedImage,
      selectedStencil: selectedStencil ?? this.selectedStencil,
      stencilOffset: stencilOffset ?? this.stencilOffset,
      stencilScale: stencilScale ?? this.stencilScale,
      stencilRotation: stencilRotation ?? this.stencilRotation,
      isFlippedHorizontally:
          isFlippedHorizontally ?? this.isFlippedHorizontally,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineThickness: outlineThickness ?? this.outlineThickness,
      outlineStyle: outlineStyle ?? this.outlineStyle,
      showOutline: showOutline ?? this.showOutline,
      fillBrightness: fillBrightness ?? this.fillBrightness,
      fillContrast: fillContrast ?? this.fillContrast,
      fillSaturation: fillSaturation ?? this.fillSaturation,
      compositeMode: compositeMode ?? this.compositeMode,
      filterType: filterType ?? this.filterType,
      text: text ?? this.text,
      textPosition: textPosition ?? this.textPosition,
      textColor: textColor ?? this.textColor,
    );
  }

  bool get hasImage => capturedImage != null;
  bool get hasStencil => selectedStencil != null;
  bool get hasText => text != null && text!.isNotEmpty;
}

/// 輪廓線樣式
enum OutlineStyle {
  solid,
  dashed,
  dotted,
}

/// 合成模式
enum CompositeMode {
  /// 只保留剪影內部，外部為白色
  fillOnly,
  
  /// 保留完整背景，剪影像窗戶
  environmentBlend,
  
  /// 夢幻模式，外部半透明
  dreamMode,
}

/// 濾鏡類型
enum FilterType {
  none,
  blackAndWhite,
  warm,
  cool,
  vintage,
  HDR,
}
