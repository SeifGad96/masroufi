import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:masroufi/core/constants/app_colors.dart';

/// Represents a spending category (starter or user-defined custom).
/// PRD §8.2b — up to 12 categories total, each auto-assigned a distinct color
/// from the fixed 12-color palette.
class CategoryModel {
  final String id;
  final String name;
  final String colorHex;
  final int colorIndex; // 0–11, position in the fixed palette
  final bool isCustom;
  final DateTime createdAt;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.colorIndex,
    required this.isCustom,
    required this.createdAt,
  });

  // ── Color helpers ─────────────────────────────────────────────────────────

  /// Returns the [Color] for this category from the fixed palette.
  /// Falls back to [AppColors.categoryColor] using [colorIndex].
  dynamic get color => AppColors.categoryPalette[colorIndex % 12];

  // ── Firestore serialization ───────────────────────────────────────────────

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      name: data['name'] as String,
      colorHex: data['colorHex'] as String,
      colorIndex: (data['colorIndex'] as num).toInt(),
      isCustom: data['isCustom'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'colorHex': colorHex,
        'colorIndex': colorIndex,
        'isCustom': isCustom,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  // ── Starter categories ────────────────────────────────────────────────────

  static List<Map<String, dynamic>> get starterCategories => [
        {'name': 'Food',           'colorIndex': 0},
        {'name': 'Transportation', 'colorIndex': 1},
        {'name': 'Bills',          'colorIndex': 2},
        {'name': 'Shopping',       'colorIndex': 3},
        {'name': 'Entertainment',  'colorIndex': 4},
        {'name': 'Health',         'colorIndex': 5},
        {'name': 'Other',          'colorIndex': 6},
      ];

  // ── Utilities ─────────────────────────────────────────────────────────────

  CategoryModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    int? colorIndex,
    bool? isCustom,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      colorIndex: colorIndex ?? this.colorIndex,
      isCustom: isCustom ?? this.isCustom,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CategoryModel(id: $id, name: $name, colorIndex: $colorIndex)';
}
