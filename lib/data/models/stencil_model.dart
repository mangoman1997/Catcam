/// 剪影模型
class StencilModel {
  final String id;
  final String name;
  final String category;
  final String assetPath;
  final String? thumbnailPath;
  final bool isPremium;
  final DateTime? unlockedAt;

  const StencilModel({
    required this.id,
    required this.name,
    required this.category,
    required this.assetPath,
    this.thumbnailPath,
    this.isPremium = false,
    this.unlockedAt,
  });

  StencilModel copyWith({
    String? id,
    String? name,
    String? category,
    String? assetPath,
    String? thumbnailPath,
    bool? isPremium,
    DateTime? unlockedAt,
  }) {
    return StencilModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      assetPath: assetPath ?? this.assetPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      isPremium: isPremium ?? this.isPremium,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'assetPath': assetPath,
      'thumbnailPath': thumbnailPath,
      'isPremium': isPremium,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory StencilModel.fromJson(Map<String, dynamic> json) {
    return StencilModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      assetPath: json['assetPath'] as String,
      thumbnailPath: json['thumbnailPath'] as String?,
      isPremium: json['isPremium'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StencilModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 剪影分類
enum StencilCategory {
  all('全部', 'all'),
  sitting('坐姿', 'sitting'),
  standing('站立', 'standing'),
  lying('躺臥', 'lying'),
  stretching('伸懶腰', 'stretching'),
  playing('玩耍', 'playing'),
  sleeping('睡覺', 'sleeping'),
  funny('搞笑', 'funny');

  final String label;
  final String value;

  const StencilCategory(this.label, this.value);
}
