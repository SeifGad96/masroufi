import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masroufi/features/auth/data/data_sources/auth_data_source.dart';
import 'package:masroufi/features/categories/data/models/category_model.dart';
import 'package:masroufi/features/expenses/data/models/expense_model.dart';
import 'package:masroufi/features/expenses/data/data_sources/expense_data_source.dart';
import 'package:masroufi/features/expenses/presentation/cubit/add_expense_state.dart';

class AddExpenseCubit extends Cubit<AddExpenseState> {
  final ExpenseDataSource _expenseDataSource;
  final AuthDataSource _authDataSource;

  CategoryModel? selectedCategory;
  DateTime selectedDate = DateTime.now();
  ExpenseModel? existingExpense;

  AddExpenseCubit({
    required ExpenseDataSource expenseDataSource,
    required AuthDataSource authDataSource,
  })  : _expenseDataSource = expenseDataSource,
        _authDataSource = authDataSource,
        super(const AddExpenseInitial());

  void loadForEdit(ExpenseModel expense, CategoryModel category) {
    existingExpense = expense;
    selectedCategory = category;
    selectedDate = expense.date;
    emit(AddExpenseInitial());
  }

  void selectCategory(CategoryModel category) {
    selectedCategory = category;
    
    emit(AddExpenseInitial());
  }

  void selectDate(DateTime date) {
    selectedDate = date;
    emit(AddExpenseInitial());
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

    final uid = _authDataSource.currentUser?.uid;
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
        await _expenseDataSource.updateExpense(uid: uid, expense: updated);
      } else {
        await _expenseDataSource.addExpense(
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
