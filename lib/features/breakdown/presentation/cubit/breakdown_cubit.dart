import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masroufi/core/constants/app_colors.dart';
import 'package:masroufi/features/auth/data/repositories/auth_repository.dart';
import 'package:masroufi/features/categories/data/repositories/category_repository.dart';
import 'package:masroufi/features/expenses/data/repositories/expense_repository.dart';
import 'package:masroufi/features/breakdown/data/repositories/budget_repository.dart';
import 'package:masroufi/features/breakdown/data/models/budget_model.dart';
import 'package:masroufi/features/breakdown/data/models/breakdown_item.dart';
import 'package:masroufi/features/breakdown/presentation/cubit/breakdown_state.dart';

class BreakdownCubit extends Cubit<BreakdownState> {
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;
  final AuthRepository _authRepository;
  final BudgetRepository _budgetRepository;

  BreakdownCubit({
    required ExpenseRepository expenseRepository,
    required CategoryRepository categoryRepository,
    required AuthRepository authRepository,
    required BudgetRepository budgetRepository,
  })  : _expenseRepository = expenseRepository,
        _categoryRepository = categoryRepository,
        _authRepository = authRepository,
        _budgetRepository = budgetRepository,
        super(const BreakdownInitial());

  Future<void> loadBreakdown() async {
    final uid = _authRepository.currentUser?.uid;
    if (uid == null) {
      emit(const BreakdownError('User is not authenticated'));
      return;
    }
    
    emit(const BreakdownLoading());
    try {
      final rawBreakdown = await _expenseRepository.getMonthlyBreakdown(uid);
      final categories = await _categoryRepository.getCategories(uid);
      final catMap = {for (final c in categories) c.id: c};
      
      final now = DateTime.now();
      final currentMonthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final budgets = await _budgetRepository.getBudgets(uid);
      final budgetMap = {
        for (final b in budgets)
          if (b.month == currentMonthStr) b.categoryId: b.limit
      };

      double totalAmount = 0.0;
      for (final item in rawBreakdown) {
        totalAmount += item['totalAmount'] as double;
      }
      
      final items = rawBreakdown.map((raw) {
        final catId = raw['categoryId'] as String;
        final cat = catMap[catId];
        return BreakdownItem(
          categoryId: catId,
          categoryName: cat?.name ?? 'Unknown',
          categoryColor: cat?.color as Color? ?? AppColors.accent,
          totalAmount: raw['totalAmount'] as double,
          percentage: raw['percentage'] as double,
          budgetLimit: budgetMap[catId],
        );
      }).toList();
      
      emit(BreakdownLoaded(items: items, totalAmount: totalAmount));
    } catch (e) {
      emit(BreakdownError(e.toString()));
    }
  }

  /// Sets or updates a monthly budget for a category.
  Future<void> updateCategoryBudget(String categoryId, double limit) async {
    final uid = _authRepository.currentUser?.uid;
    if (uid == null) return;

    try {
      final now = DateTime.now();
      final currentMonthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final budget = BudgetModel(
        categoryId: categoryId,
        limit: limit,
        month: currentMonthStr,
      );

      await _budgetRepository.setBudget(uid: uid, budget: budget);
      await loadBreakdown();
    } catch (e) {
      debugPrint('Failed to set category budget: $e');
    }
  }

  /// Deletes a budget limit for a category.
  Future<void> removeCategoryBudget(String categoryId) async {
    final uid = _authRepository.currentUser?.uid;
    if (uid == null) return;

    try {
      await _budgetRepository.deleteBudget(uid: uid, categoryId: categoryId);
      await loadBreakdown();
    } catch (e) {
      debugPrint('Failed to remove category budget: $e');
    }
  }
}
