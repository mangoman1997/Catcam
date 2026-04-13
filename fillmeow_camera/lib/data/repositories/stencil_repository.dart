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
    // 坐姿
    const StencilModel(
      id: 'sitting_01',
      name: '乖巧坐姿',
      category: 'sitting',
      assetPath: 'assets/stencils/sitting_01.png',
    ),
    const StencilModel(
      id: 'sitting_02',
      name: '側坐貓',
      category: 'sitting',
      assetPath: 'assets/stencils/sitting_02.png',
    ),
    const StencilModel(
      id: 'sitting_03',
      name: '立正坐',
      category: 'sitting',
      assetPath: 'assets/stencils/sitting_03.png',
    ),

    // 站立
    const StencilModel(
      id: 'standing_01',
      name: '四足站立',
      category: 'standing',
      assetPath: 'assets/stencils/standing_01.png',
    ),
    const StencilModel(
      id: 'standing_02',
      name: '好奇站立',
      category: 'standing',
      assetPath: 'assets/stencils/standing_02.png',
    ),

    // 躺臥
    const StencilModel(
      id: 'lying_01',
      name: '側躺休息',
      category: 'lying',
      assetPath: 'assets/stencils/lying_01.png',
    ),
    const StencilModel(
      id: 'lying_02',
      name: '趴著放鬆',
      category: 'lying',
      assetPath: 'assets/stencils/lying_02.png',
    ),

    // 伸懶腰
    const StencilModel(
      id: 'stretching_01',
      name: '拱背伸懶腰',
      category: 'stretching',
      assetPath: 'assets/stencils/stretching_01.png',
    ),
    const StencilModel(
      id: 'stretching_02',
      name: '前伸懶腰',
      category: 'stretching',
      assetPath: 'assets/stencils/stretching_02.png',
    ),

    // 玩耍
    const StencilModel(
      id: 'playing_01',
      name: '跳躍姿勢',
      category: 'playing',
      assetPath: 'assets/stencils/playing_01.png',
    ),
    const StencilModel(
      id: 'playing_02',
      name: '追逐姿勢',
      category: 'playing',
      assetPath: 'assets/stencils/playing_02.png',
    ),
    const StencilModel(
      id: 'playing_03',
      name: '探頭好奇',
      category: 'playing',
      assetPath: 'assets/stencils/playing_03.png',
    ),

    // 睡覺
    const StencilModel(
      id: 'sleeping_01',
      name: '捲成一球',
      category: 'sleeping',
      assetPath: 'assets/stencils/sleeping_01.png',
    ),
    const StencilModel(
      id: 'sleeping_02',
      name: '趴著睡',
      category: 'sleeping',
      assetPath: 'assets/stencils/sleeping_02.png',
    ),

    // 搞笑
    const StencilModel(
      id: 'funny_01',
      name: '偷吃姿勢',
      category: 'funny',
      assetPath: 'assets/stencils/funny_01.png',
    ),
    const StencilModel(
      id: 'funny_02',
      name: '眨眼貓',
      category: 'funny',
      assetPath: 'assets/stencils/funny_02.png',
    ),
    const StencilModel(
      id: 'funny_03',
      name: '胖嘟嘟球',
      category: 'funny',
      assetPath: 'assets/stencils/funny_03.png',
    ),
  ];
}
