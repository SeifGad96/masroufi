import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masroufi/features/auth/data/repositories/auth_repository.dart';
import 'package:masroufi/features/categories/data/models/category_model.dart';
import 'package:masroufi/features/expenses/data/models/expense_model.dart';
import 'package:masroufi/features/expenses/data/repositories/expense_repository.dart';
import 'package:masroufi/features/expenses/presentation/cubit/add_expense_state.dart';

class AddExpenseCubit extends Cubit<AddExpenseState> {
  final ExpenseRepository _expenseRepository;
  final AuthRepository _authRepository;

  CategoryModel? selectedCategory;
  DateTime selectedDate = DateTime.now();
  ExpenseModel? existingExpense;

  AddExpenseCubit({
    required ExpenseRepository expenseRepository,
    required AuthRepository authRepository,
  })  : _expenseRepository = expenseRepository,
        _authRepository = authRepository,
        super(const AddExpenseInitial());

  void loadForEdit(ExpenseModel expense, CategoryModel category) {
    existingExpense = expense;
    selectedCategory = category;
    selectedDate = expense.date;
    emit(const AddExpenseInitial());
  }

  void selectCategory(CategoryModel category) {
    selectedCategory = category;
    // Emit initial to trigger UI updates if necessary, or just keep state
    emit(const AddExpenseInitial());
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    emit(const AddExpenseInitial());
  }

  Future<void> submitExpense({
    required String amountStr,
    String? note,
  }) async {
    final amount = double.tryParse(amountStr.trim()) ?? 0.0;

    if (amount <= 0) {
      emit(const AddExpenseError('Please enter a valid amount greater than 0'));
      return;
    }

    if (selectedCategory == null) {
      emit(const AddExpenseError('Please select a category'));
      return;
    }

    final uid = _authRepository.currentUser?.uid;
    if (uid == null) {
      emit(const AddExpenseError('User is not authenticated'));
      return;
    }

    emit(const AddExpenseLoading());

    try {
      if (existingExpense != null) {
        final updated = existingExpense!.copyWith(
          amount: amount,
          categoryId: selectedCategory!.id,
          date: selectedDate,
          note: note?.trim().isEmpty == true ? null : note?.trim(),
          synced: false,
        );
        await _expenseRepository.updateExpense(uid: uid, expense: updated);
      } else {
        await _expenseRepository.addExpense(
          uid: uid,
          amount: amount,
          categoryId: selectedCategory!.id,
          date: selectedDate,
          note: note?.trim().isEmpty == true ? null : note?.trim(),
        );
      }
      emit(const AddExpenseSuccess());
    } catch (e) {
      emit(AddExpenseError(e.toString()));
    }
  }
}
