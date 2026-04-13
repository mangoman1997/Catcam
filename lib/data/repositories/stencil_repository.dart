import '../models/stencil_model.dart';

/// 剪影倉庫
class StencilRepository {
  /// 獲取所有剪影
  List<StencilModel> getAllStencils() {
    return _defaultStencils;
  }

  /// 按分類獲取剪影
  List<StencilModel> getStencilsByCategory(StencilCategory category) {
    if (category == StencilCategory.all) {
      return _defaultStencils;
    }
    return _defaultStencils
        .where((s) => s.category == category.value)
        .toList();
  }

  /// 搜尋剪影
  List<StencilModel> searchStencils(String query) {
    final lowerQuery = query.toLowerCase();
    return _defaultStencils
        .where((s) =>
            s.name.toLowerCase().contains(lowerQuery) ||
            s.category.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// 預設剪影列表
  static final List<StencilModel> _defaultStencils = [
    // 剪影系列（使用者提供的黑色剪影）
    const StencilModel(
      id: 'cat_silhouette',
      name: '🐱 貓咪剪影',
      category: 'silhouette',
      assetPath: 'assets/stencils/cat_silhouette.png',
    ),
  ];
}
