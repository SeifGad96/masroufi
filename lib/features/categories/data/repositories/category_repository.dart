import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:masroufi/core/constants/app_colors.dart';
import 'package:masroufi/features/categories/data/models/category_model.dart';

/// Handles all Firestore operations for categories.
/// PRD §8.2b — categories live at users/{uid}/categories/
class CategoryRepository {
  final FirebaseFirestore _firestore;

  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ── Collection reference ──────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _categoriesRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('categories');

  // ── Seeding ───────────────────────────────────────────────────────────────

  /// Seeds the 7 starter categories for a newly created account.
  /// Runs inside a batched write for atomicity.
  /// No-ops if categories already exist (idempotent).
  Future<void> seedStarterCategories(String uid) async {
    final existing = await _categoriesRef(uid).limit(1).get();
    if (existing.docs.isNotEmpty) return; // already seeded

    final batch = _firestore.batch();
    final now = DateTime.now();
    final palette = AppColors.categoryPalette;

    for (final entry in CategoryModel.starterCategories) {
      final ref = _categoriesRef(uid).doc();
      final colorIndex = entry['colorIndex'] as int;
      batch.set(ref, {
        'name': entry['name'],
        'colorHex': _colorToHex(palette[colorIndex]),
        'colorIndex': colorIndex,
        'isCustom': false,
        'createdAt': Timestamp.fromDate(now),
      });
    }

    await batch.commit();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  /// Returns a real-time stream of all categories for [uid], sorted by colorIndex.
  Stream<List<CategoryModel>> watchCategories(String uid) {
    return _categoriesRef(uid)
        .orderBy('colorIndex')
        .snapshots()
        .map((snap) => snap.docs.map(CategoryModel.fromFirestore).toList());
  }

  /// Fetches all categories once.
  Future<List<CategoryModel>> getCategories(String uid) async {
    final snap =
        await _categoriesRef(uid).orderBy('colorIndex').get();
    return snap.docs.map(CategoryModel.fromFirestore).toList();
  }

  /// Adds a new custom category. Auto-assigns the next unused color index.
  /// Throws [StateError] if the 12-category cap is already reached.
  Future<CategoryModel> addCustomCategory({
    required String uid,
    required String name,
  }) async {
    final existing = await getCategories(uid);
    if (existing.length >= 12) {
      throw StateError(
        'Category limit reached (12). Delete a category to add a new one.',
      );
    }

    final usedIndices = existing.map((c) => c.colorIndex).toSet();
    final nextIndex =
        List.generate(12, (i) => i).firstWhere((i) => !usedIndices.contains(i));

    final color = AppColors.categoryPalette[nextIndex];
    final hex = _colorToHex(color);
    final now = DateTime.now();

    final ref = _categoriesRef(uid).doc();
    final data = {
      'name': name.trim(),
      'colorHex': hex,
      'colorIndex': nextIndex,
      'isCustom': true,
      'createdAt': Timestamp.fromDate(now),
    };

    await ref.set(data);

    return CategoryModel(
      id: ref.id,
      name: name.trim(),
      colorHex: hex,
      colorIndex: nextIndex,
      isCustom: true,
      createdAt: now,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _colorToHex(Color color) {
    final r = color.r.toInt().toRadixString(16).padLeft(2, '0');
    final g = color.g.toInt().toRadixString(16).padLeft(2, '0');
    final b = color.b.toInt().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }
}
