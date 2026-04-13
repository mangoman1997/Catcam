import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/editor_state.dart';
import '../data/models/stencil_model.dart';

/// 編輯器狀態Provider
final editorStateProvider =
    StateNotifierProvider<EditorStateNotifier, EditorState>((ref) {
  return EditorStateNotifier();
});

/// 編輯器狀態Notifier
class EditorStateNotifier extends StateNotifier<EditorState> {
  EditorStateNotifier() : super(const EditorState());

  /// 設置拍攝的圖片
  void setCapturedImage(Uint8List image) {
    state = state.copyWith(capturedImage: image);
  }

  /// 選擇剪影
  void selectStencil(StencilModel stencil) {
    state = state.copyWith(
      selectedStencil: stencil,
      stencilOffset: Offset.zero,
      stencilScale: 1.0,
      stencilRotation: 0.0,
    );
  }

  /// 清除剪影
  void clearStencil() {
    state = EditorState(capturedImage: state.capturedImage);
  }

  /// 更新剪影位置
  void updateStencilOffset(Offset offset) {
    state = state.copyWith(stencilOffset: offset);
  }

  /// 更新剪影縮放
  void updateStencilScale(double scale) {
    state = state.copyWith(stencilScale: scale);
  }

  /// 更新剪影旋轉
  void updateStencilRotation(double rotation) {
    state = state.copyWith(stencilRotation: rotation);
  }

  /// 翻轉剪影
  void flipStencil() {
    state = state.copyWith(
      isFlippedHorizontally: !state.isFlippedHorizontally,
    );
  }

  /// 更新輪廓線顏色
  void updateOutlineColor(Color color) {
    state = state.copyWith(outlineColor: color);
  }

  /// 更新輪廓線粗細
  void updateOutlineThickness(double thickness) {
    state = state.copyWith(outlineThickness: thickness);
  }

  /// 更新輪廓線樣式
  void updateOutlineStyle(OutlineStyle style) {
    state = state.copyWith(outlineStyle: style);
  }

  /// 切換顯示輪廓線
  void toggleOutline() {
    state = state.copyWith(showOutline: !state.showOutline);
  }

  /// 更新填滿參數
  void updateFillBrightness(double value) {
    state = state.copyWith(fillBrightness: value);
  }

  void updateFillContrast(double value) {
    state = state.copyWith(fillContrast: value);
  }

  void updateFillSaturation(double value) {
    state = state.copyWith(fillSaturation: value);
  }

  /// 更新合成模式
  void updateCompositeMode(CompositeMode mode) {
    state = state.copyWith(compositeMode: mode);
  }

  /// 更新濾鏡
  void updateFilter(FilterType filter) {
    state = state.copyWith(filterType: filter);
  }

  /// 添加文字
  void addText(String text, Offset position, Color color) {
    state = state.copyWith(
      text: text,
      textPosition: position,
      textColor: color,
    );
  }

  /// 清除文字
  void clearText() {
    state = state.copyWith(text: null, textPosition: null, textColor: null);
  }

  /// 重置編輯器
  void reset() {
    state = const EditorState();
  }
}
