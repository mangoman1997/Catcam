import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/stencil_model.dart';
import '../data/repositories/stencil_repository.dart';

/// 剪影倉庫Provider
final stencilRepositoryProvider = Provider<StencilRepository>((ref) {
  return StencilRepository();
});

/// 當前選中的分類
final selectedCategoryProvider = StateProvider<StencilCategory>((ref) {
  return StencilCategory.all;
});

/// 剪影列表Provider
final stencilListProvider = Provider<List<StencilModel>>((ref) {
  final repository = ref.watch(stencilRepositoryProvider);
  final category = ref.watch(selectedCategoryProvider);
  return repository.getStencilsByCategory(category);
});

/// 搜尋關鍵字
final searchQueryProvider = StateProvider<String>((ref) {
  return '';
});

/// 搜尋結果Provider
final searchedStencilsProvider = Provider<List<StencilModel>>((ref) {
  final repository = ref.watch(stencilRepositoryProvider);
  final query = ref.watch(searchQueryProvider);
  
  if (query.isEmpty) {
    return ref.watch(stencilListProvider);
  }
  
  return repository.searchStencils(query);
});

/// 選中的剪影Provider
final selectedStencilProvider = StateProvider<StencilModel?>((ref) {
  return null;
});
