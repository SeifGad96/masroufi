import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:masroufi/core/constants/app_colors.dart';
import 'package:masroufi/core/constants/app_text_styles.dart';
import 'package:masroufi/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:masroufi/features/auth/presentation/cubit/auth_state.dart';
import 'package:masroufi/features/categories/data/models/category_model.dart';
import 'package:masroufi/features/categories/data/repositories/category_repository.dart';
import 'package:masroufi/features/expenses/data/models/expense_model.dart';
import 'package:masroufi/features/expenses/data/repositories/expense_repository.dart';
import 'package:masroufi/features/expenses/presentation/screens/add_expense_screen.dart';

abstract class HistoryItem {}

class HeaderItem extends HistoryItem {
  final DateTime date;
  HeaderItem(this.date);
}

class ExpenseItem extends HistoryItem {
  final ExpenseModel expense;
  ExpenseItem(this.expense);
}

class ExpenseHistoryScreen extends StatelessWidget {
  const ExpenseHistoryScreen({super.key});

  Map<DateTime, List<ExpenseModel>> _groupExpenses(List<ExpenseModel> expenses) {
    final Map<DateTime, List<ExpenseModel>> grouped = {};
    for (final expense in expenses) {
      final normalizedDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      if (!grouped.containsKey(normalizedDate)) {
        grouped[normalizedDate] = [];
      }
      grouped[normalizedDate]!.add(expense);
    }
    return grouped;
  }

  String _formatHeaderDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Today';
    } else if (target == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.yMMMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final uid = authState is AuthAuthenticated ? authState.user.uid : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: StreamBuilder<List<CategoryModel>>(
        stream: context.read<CategoryRepository>().watchCategories(uid),
        builder: (context, catSnapshot) {
          if (catSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          final categories = catSnapshot.data ?? [];
          final catMap = {for (final c in categories) c.id: c};

          return StreamBuilder<List<ExpenseModel>>(
            stream: context.read<ExpenseRepository>().watchExpenses(uid),
            builder: (context, expSnapshot) {
              if (expSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                );
              }

              final expenses = expSnapshot.data ?? [];

              if (expenses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: AppColors.accent,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('No expenses yet', style: AppTextStyles.headlineMedium),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to add a new expense',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              final grouped = _groupExpenses(expenses);
              final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

              final List<HistoryItem> items = [];
              for (final date in sortedKeys) {
                items.add(HeaderItem(date));
                for (final exp in grouped[date]!) {
                  items.add(ExpenseItem(exp));
                }
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  if (item is HeaderItem) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 8),
                      child: Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _formatHeaderDate(item.date),
                              style: AppTextStyles.labelLarge.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                    );
                  }

                  if (item is ExpenseItem) {
                    final expense = item.expense;
                    final category = catMap[expense.categoryId];
                    final color = category?.color as Color? ?? AppColors.accent;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.surface,
                              title: Text(
                                'Delete Expense',
                                style: AppTextStyles.titleLarge,
                              ),
                              content: Text(
                                'Are you sure you want to delete this expense?',
                                style: AppTextStyles.bodyMedium,
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(
                                    'Cancel',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          await context.read<ExpenseRepository>().deleteExpense(
                            uid: uid,
                            expenseId: expense.id,
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Expense deleted'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.error,
                          ),
                        ),
                        child: Card(
                          margin: EdgeInsets.zero,
                          color: AppColors.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: color.withValues(alpha: 0.15),
                              child: Icon(Icons.circle, color: color, size: 10),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  category?.name ?? 'Unknown',
                                  style: AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '-${expense.amount.toStringAsFixed(2)}',
                                  style: AppTextStyles.amountMedium.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: expense.note != null && expense.note!.isNotEmpty
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      expense.note!,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )
                                : null,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddExpenseScreen(
                                    expense: expense,
                                    category: category,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddExpenseScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
