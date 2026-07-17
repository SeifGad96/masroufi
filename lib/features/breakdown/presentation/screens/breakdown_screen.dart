import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masroufi/core/constants/app_colors.dart';
import 'package:masroufi/core/constants/app_text_styles.dart';
import 'package:masroufi/features/breakdown/presentation/cubit/breakdown_cubit.dart';
import 'package:masroufi/features/breakdown/presentation/cubit/breakdown_state.dart';
import 'package:masroufi/features/breakdown/data/models/breakdown_item.dart';

class BreakdownScreen extends StatefulWidget {
  const BreakdownScreen({super.key});

  @override
  State<BreakdownScreen> createState() => _BreakdownScreenState();
}

class _BreakdownScreenState extends State<BreakdownScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BreakdownCubit>().loadBreakdown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Breakdown'),
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<BreakdownCubit>().loadBreakdown(),
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        child: BlocBuilder<BreakdownCubit, BreakdownState>(
          builder: (context, state) {
            if (state is BreakdownLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }

            if (state is BreakdownError) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text('Error loading breakdown', style: AppTextStyles.titleLarge),
                      const SizedBox(height: 8),
                      Text(state.message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<BreakdownCubit>().loadBreakdown(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is BreakdownLoaded) {
              final items = state.items;
              final totalAmount = state.totalAmount;

              if (items.isEmpty || totalAmount <= 0) {
                return Center(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            Icons.pie_chart_outline_rounded,
                            color: AppColors.accent,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('No spending data', style: AppTextStyles.headlineMedium),
                        const SizedBox(height: 8),
                        Text(
                          'Add expenses this month to view category breakdown.',
                          style: AppTextStyles.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                itemCount: items.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'This Month\'s Total',
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              totalAmount.toStringAsFixed(2),
                              style: AppTextStyles.amountLarge.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final item = items[index - 1];
                  final hasBudget = item.budgetLimit != null && item.budgetLimit! > 0;
                  final budgetLimit = item.budgetLimit ?? 0.0;
                  final isExceeded = hasBudget && item.totalAmount > budgetLimit;

                  final progressFactor = hasBudget
                      ? (item.totalAmount / budgetLimit).clamp(0.0, 1.0)
                      : (item.percentage / 100).clamp(0.0, 1.0);

                  final barColor = isExceeded ? AppColors.error : item.categoryColor;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 6,
                                  backgroundColor: item.categoryColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.categoryName,
                                        style: AppTextStyles.titleMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (hasBudget) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Budget: ${budgetLimit.toStringAsFixed(2)}',
                                          style: AppTextStyles.labelSmall.copyWith(
                                            color: isExceeded ? AppColors.error : AppColors.textSecondary,
                                            fontWeight: isExceeded ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ] else ...[
                                        const SizedBox(height: 2),
                                        InkWell(
                                          onTap: () => _showBudgetDialog(context, item),
                                          child: Text(
                                            'Set budget limit',
                                            style: AppTextStyles.labelSmall.copyWith(
                                              color: AppColors.accent,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      item.totalAmount.toStringAsFixed(2),
                                      style: AppTextStyles.amountMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (hasBudget) ...[
                                      const SizedBox(height: 2),
                                      GestureDetector(
                                        onTap: () => _showBudgetDialog(context, item),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.edit_outlined,
                                              size: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Edit limit',
                                              style: AppTextStyles.labelSmall.copyWith(
                                                color: AppColors.textSecondary,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              height: 8,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progressFactor,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: barColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.percentage.toStringAsFixed(1)}% of total spent',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                                if (hasBudget)
                                  Text(
                                    isExceeded
                                        ? 'Exceeded by ${(item.totalAmount - budgetLimit).toStringAsFixed(2)}!'
                                        : '${((item.totalAmount / budgetLimit) * 100).toStringAsFixed(1)}% of budget',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: isExceeded ? AppColors.error : AppColors.success,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  void _showBudgetDialog(BuildContext context, BreakdownItem item) {
    final controller = TextEditingController(
      text: item.budgetLimit != null ? item.budgetLimit!.toStringAsFixed(2) : '',
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Set Budget for ${item.categoryName}',
            style: AppTextStyles.titleLarge,
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Monthly Budget Limit',
                hintText: '0.00',
                prefixIcon: Icon(Icons.money_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a limit';
                }
                final limit = double.tryParse(value);
                if (limit == null || limit < 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            if (item.budgetLimit != null)
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await context.read<BreakdownCubit>().removeCategoryBudget(item.categoryId);
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Remove'),
              )
            else
              const SizedBox.shrink(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(64, 40),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final limit = double.tryParse(controller.text) ?? 0.0;
                      Navigator.pop(dialogContext);
                      await context.read<BreakdownCubit>().updateCategoryBudget(item.categoryId, limit);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}