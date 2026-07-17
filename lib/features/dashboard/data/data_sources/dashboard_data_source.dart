import 'package:masroufi/features/dashboard/data/models/dashboard_summary.dart';
import 'package:masroufi/features/expenses/data/data_sources/expense_data_source.dart';

class DashboardDataSource {
  final ExpenseDataSource _expenseDataSource;

  DashboardDataSource({required ExpenseDataSource expenseDataSource})
      : _expenseDataSource = expenseDataSource;

  
  Future<DashboardSummary> getSummary(String uid) async {
    final expenses = await _expenseDataSource.getExpenses(uid);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    
    final weekday = now.weekday;
    final startOfWeek = today.subtract(Duration(days: weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);

    double todayTotal = 0.0;
    double weekTotal = 0.0;
    double monthTotal = 0.0;

    for (final exp in expenses) {
      final expDate = DateTime(exp.date.year, exp.date.month, exp.date.day);
      
      
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
