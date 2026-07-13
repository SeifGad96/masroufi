import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masroufi/core/constants/app_colors.dart';
import 'package:masroufi/features/auth/data/repositories/auth_repository.dart';
import 'package:masroufi/features/categories/data/repositories/category_repository.dart';
import 'package:masroufi/features/expenses/data/repositories/expense_repository.dart';
import 'package:masroufi/features/breakdown/data/models/breakdown_item.dart';
import 'package:masroufi/features/breakdown/presentation/cubit/breakdown_state.dart';

class BreakdownCubit extends Cubit<BreakdownState> {
  final ExpenseRepository _expenseRepository;
  final CategoryRepository _categoryRepository;
  final AuthRepository _authRepository;

  BreakdownCubit({
    required ExpenseRepository expenseRepository,
    required CategoryRepository categoryRepository,
    required AuthRepository authRepository,
  })  : _expenseRepository = expenseRepository,
        _categoryRepository = categoryRepository,
        _authRepository = authRepository,
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
        );
      }).toList();
      
      emit(BreakdownLoaded(items: items, totalAmount: totalAmount));
    } catch (e) {
      emit(BreakdownError(e.toString()));
    }
  }
}
