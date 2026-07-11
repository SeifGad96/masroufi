import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

/// Bottom-navigation shell that hosts the four main tabs.
/// The News tab lives here as the single integration point per PRD §9.1.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _currentIndex = 0;

  // Screens are created lazily on first visit using IndexedStack so that
  // each tab's state is preserved across switches.
  static const List<Widget> _screens = [
    _DashboardPlaceholder(),
    _ExpensesPlaceholder(),
    _BreakdownPlaceholder(),
    _NewsPlaceholder(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _AppBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textMuted,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: AppTextStyles.labelSmall.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.labelSmall,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Expenses',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pie_chart_outline_rounded),
              activeIcon: Icon(Icons.pie_chart_rounded),
              label: 'Breakdown',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.newspaper_outlined),
              activeIcon: Icon(Icons.newspaper_rounded),
              label: 'News',
            ),
          ],
        ),
      ),
    );
  }
}

// ── Placeholder screens (will be replaced in M2–M5) ──────────────────────────

class _DashboardPlaceholder extends StatelessWidget {
  const _DashboardPlaceholder();

  @override
  Widget build(BuildContext context) {
    return _PlaceholderScreen(
      icon: Icons.dashboard_rounded,
      title: 'Dashboard',
      subtitle: 'Coming in Milestone 4',
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
    );
  }
}

class _ExpensesPlaceholder extends StatelessWidget {
  const _ExpensesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      icon: Icons.receipt_long_rounded,
      title: 'Expenses',
      subtitle: 'Coming in Milestone 2',
    );
  }
}

class _BreakdownPlaceholder extends StatelessWidget {
  const _BreakdownPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      icon: Icons.pie_chart_rounded,
      title: 'Breakdown',
      subtitle: 'Coming in Milestone 4',
    );
  }
}

class _NewsPlaceholder extends StatelessWidget {
  const _NewsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const _PlaceholderScreen(
      icon: Icons.newspaper_rounded,
      title: 'News',
      subtitle: 'Coming in Milestone 5',
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget>? actions;

  const _PlaceholderScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: Center(
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
              child: Icon(icon, color: AppColors.accent, size: 40),
            ),
            const SizedBox(height: 20),
            Text(title, style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
