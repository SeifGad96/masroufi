import 'package:masroufi/features/dashboard/data/models/dashboard_summary.dart';
import 'package:masroufi/features/expenses/data/repositories/expense_repository.dart';

class DashboardRepository {
  final ExpenseRepository _expenseRepository;

  DashboardRepository({required ExpenseRepository expenseRepository})
      : _expenseRepository = expenseRepository;

  /// Computes today, week, and month totals from the full expense list.
  Future<DashboardSummary> getSummary(String uid) async {
    final expenses = await _expenseRepository.getExpenses(uid);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Monday of this week (1 = Monday, 7 = Sunday)
    final weekday = now.weekday;
    final startOfWeek = today.subtract(Duration(days: weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    double todayTotal = 0.0;
    double weekTotal = 0.0;
    double monthTotal = 0.0;

    for (final exp in expenses) {
      final expDate = DateTime(exp.date.year, exp.date.month, exp.date.day);
      
      // Since expenses are sorted by date descending, we check matches:
      if (expDate == today) {
        todayTotal += exp.amount;
      }
      if (!expDate.isBefore(startOfWeek)) {
        weekTotal += exp.amount;
      }
      if (!expDate.isBefore(startOfMonth)) {
        monthTotal += exp.amount;
      }
    }

    return DashboardSummary(
      todayTotal: todayTotal,
      weekTotal: weekTotal,
      monthTotal: monthTotal,
    );
  }
}
