import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:masroufi/core/constants/app_colors.dart';
import 'package:masroufi/core/constants/app_routes.dart';
import 'package:masroufi/core/constants/app_text_styles.dart';
import 'package:masroufi/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:masroufi/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:masroufi/features/dashboard/presentation/cubit/dashboard_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardCubit>().loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await context.read<AuthCubit>().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Sign out'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardCubit>().loadSummary(),
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              );
            }

            if (state is DashboardError) {
              return Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text('Error loading dashboard', style: AppTextStyles.titleLarge),
                      const SizedBox(height: 8),
                      Text(state.message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<DashboardCubit>().loadSummary(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state is DashboardLoaded) {
              final summary = state.summary;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome header
                    Text(
                      'Welcome to مصروفي',
                      style: AppTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Here is your spending overview',
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 28),

                    // Today Summary Card (Full Width)
                    _SummaryCard(
                      title: 'Today',
                      amount: summary.todayTotal,
                      icon: Icons.calendar_today_rounded,
                      color: AppColors.accent,
                      isLarge: true,
                    ),
                    const SizedBox(height: 16),

                    // Side-by-side cards for Week & Month
                    Row(
                      children: [
                        Expanded(
                          child: _SummaryCard(
                            title: 'This Week',
                            amount: summary.weekTotal,
                            icon: Icons.date_range_rounded,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _SummaryCard(
                            title: 'This Month',
                            amount: summary.monthTotal,
                            icon: Icons.calendar_month_rounded,
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Call to action / Empty state message if total is 0
                    if (summary.monthTotal == 0) ...[
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.receipt_long_rounded,
                                color: AppColors.textMuted,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start tracking your expenses!',
                              style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the Expenses tab and use the + button to add a new transaction.',
                              style: AppTextStyles.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final bool isLarge;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: color, width: 4),
            ),
          ),
          padding: EdgeInsets.all(isLarge ? 24.0 : 18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    icon,
                    color: color.withValues(alpha: 0.8),
                    size: isLarge ? 24 : 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                amount.toStringAsFixed(2),
                style: isLarge ? AppTextStyles.amountLarge : AppTextStyles.amountMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
