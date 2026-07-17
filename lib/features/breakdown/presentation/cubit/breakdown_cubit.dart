import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masroufi/core/constants/app_colors.dart';
import 'package:masroufi/features/auth/data/data_sources/auth_data_source.dart';
import 'package:masroufi/features/categories/data/data_sources/category_data_source.dart';
import 'package:masroufi/features/expenses/data/data_sources/expense_data_source.dart';
import 'package:masroufi/features/breakdown/data/data_sources/budget_data_source.dart';
import 'package:masroufi/features/breakdown/data/models/budget_model.dart';
import 'package:masroufi/features/breakdown/data/models/breakdown_item.dart';
import 'package:masroufi/features/breakdown/presentation/cubit/breakdown_state.dart';

class BreakdownCubit extends Cubit<BreakdownState> {
  final ExpenseDataSource _expenseDataSource;
  final CategoryDataSource _categoryDataSource;
  final AuthDataSource _authDataSource;
  final BudgetDataSource _budgetDataSource;

  BreakdownCubit({
    required ExpenseDataSource expenseDataSource,
    required CategoryDataSource categoryDataSource,
    required AuthDataSource authDataSource,
    required BudgetDataSource budgetDataSource,
  })  : _expenseDataSource = expenseDataSource,
        _categoryDataSource = categoryDataSource,
        _authDataSource = authDataSource,
        _budgetDataSource = budgetDataSource,
        super(const BreakdownInitial());

  Future<void> loadBreakdown() async {
    final uid = _authDataSource.currentUser?.uid;
    if (uid == null) {
      emit(const BreakdownError('User is not authenticated'));
      return;
    }
    
    emit(const BreakdownLoading());
    try {
      final rawBreakdown = await _expenseDataSource.getMonthlyBreakdown(uid);
      final categories = await _categoryDataSource.getCategories(uid);
      final catMap = {for (final c in categories) c.id: c};
      
      final now = DateTime.now();
      final currentMonthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final budgets = await _budgetDataSource.getBudgets(uid);
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

  
  Future<void> updateCategoryBudget(String categoryId, double limit) async {
    final uid = _authDataSource.currentUser?.uid;
    if (uid == null) return;

    try {
      final now = DateTime.now();
      final currentMonthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      
      final budget = BudgetModel(
        categoryId: categoryId,
        limit: limit,
        month: currentMonthStr,
      );

      await _budgetDataSource.setBudget(uid: uid, budget: budget);
      await loadBreakdown();
    } catch (e) {
      debugPrint('Failed to set category budget: $e');
    }
  }

  
  Future<void> removeCategoryBudget(String categoryId) async {
    final uid = _authDataSource.currentUser?.uid;
    if (uid == null) return;

    try {
      await _budgetDataSource.deleteBudget(uid: uid, categoryId: categoryId);
      await loadBreakdown();
    } catch (e) {
      debugPrint('Failed to remove category budget: $e');
    }
  }
}
