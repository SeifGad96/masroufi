import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:masroufi/core/constants/app_colors.dart';
import 'package:masroufi/core/constants/app_text_styles.dart';
import 'package:masroufi/features/auth/data/data_sources/auth_data_source.dart';
import 'package:masroufi/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:masroufi/features/auth/presentation/cubit/auth_state.dart';
import 'package:masroufi/features/categories/data/models/category_model.dart';
import 'package:masroufi/features/categories/data/data_sources/category_data_source.dart';
import 'package:masroufi/features/expenses/data/data_sources/expense_data_source.dart';
import 'package:masroufi/features/expenses/data/models/expense_model.dart';
import 'package:masroufi/features/expenses/presentation/cubit/add_expense_cubit.dart';
import 'package:masroufi/features/expenses/presentation/cubit/add_expense_state.dart';

import '../../../../core/widgets/app_widgets.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? expense;
  final CategoryModel? category;

  const AddExpenseScreen({
    super.key,
    this.expense,
    this.category,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();
  final _noteFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      _amountController.text = widget.expense!.amount.toStringAsFixed(2);
      _noteController.text = widget.expense!.note ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final uid = authState is AuthAuthenticated ? authState.user.uid : '';

    return BlocProvider(
      create: (context) {
        final cubit = AddExpenseCubit(
          expenseDataSource: context.read<ExpenseDataSource>(),
          authDataSource: context.read<AuthDataSource>(),
        );
        if (widget.expense != null && widget.category != null) {
          cubit.loadForEdit(widget.expense!, widget.category!);
        }
        return cubit;
      },
      child: Builder(
        builder: (context) {
          final cubit = context.watch<AddExpenseCubit>();

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(widget.expense != null ? 'Edit Expense' : 'Add Expense'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: BlocListener<AddExpenseCubit, AddExpenseState>(
              listener: (context, state) {
                if (state is AddExpenseSuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.expense != null
                          ? 'Expense updated successfully'
                          : 'Expense added successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  Navigator.pop(context, true);
                } else if (state is AddExpenseError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        AppTextField(
                          controller: _amountController,
                          label: 'Amount',
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          focusNode: _amountFocus,
                          autofocus: true,
                          prefixIcon: const Icon(Icons.calculate_outlined),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Amount is required';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'Please enter a valid amount greater than 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        
                        Text(
                          'Category',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        
                        StreamBuilder<List<CategoryModel>>(
                          stream: context.read<CategoryDataSource>().watchCategories(uid),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox(
                                height: 48,
                                child: Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            }

                            final categories = snapshot.data ?? [];
                            if (categories.isEmpty) {
                              return Text(
                                'No categories found. Please reload or contact support.',
                                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
                              );
                            }

                            return SizedBox(
                              height: 48,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: categories.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  final isSelected = cubit.selectedCategory?.id == category.id;
                                  final color = category.color as Color;

                                  return ChoiceChip(
                                    label: Text(category.name),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        cubit.selectCategory(category);
                                      }
                                    },
                                    selectedColor: color.withValues(alpha: 0.15),
                                    checkmarkColor: color,
                                    labelStyle: AppTextStyles.labelLarge.copyWith(
                                      color: isSelected ? color : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                    avatar: CircleAvatar(
                                      radius: 6,
                                      backgroundColor: color,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        
                        Text(
                          'Date',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        
                        InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: cubit.selectedDate,
                              firstDate: DateTime(DateTime.now().year - 5),
                              lastDate: DateTime(DateTime.now().year + 5),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.dark(
                                      primary: AppColors.accent,
                                      onPrimary: Colors.white,
                                      surface: AppColors.surface,
                                      onSurface: AppColors.textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (pickedDate != null) {
                              cubit.selectDate(pickedDate);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, color: AppColors.textMuted, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat.yMMMMd().format(cubit.selectedDate),
                                  style: AppTextStyles.bodyLarge,
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        
                        AppTextField(
                          controller: _noteController,
                          label: 'Note (Optional)',
                          hint: 'Enter a note...',
                          focusNode: _noteFocus,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          prefixIcon: const Icon(Icons.notes),
                        ),
                        const SizedBox(height: 40),

                        
                        BlocBuilder<AddExpenseCubit, AddExpenseState>(
                          builder: (context, state) {
                            return PrimaryButton(
                              label: widget.expense != null ? 'Save Changes' : 'Add Expense',
                              isLoading: state is AddExpenseLoading,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  cubit.submitExpense(
                                    amountStr: _amountController.text,
                                    note: _noteController.text,
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
