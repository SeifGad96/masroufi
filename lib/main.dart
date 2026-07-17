import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_routes.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/data/data_sources/auth_data_source.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/categories/data/data_sources/category_data_source.dart';
import 'features/expenses/data/data_sources/expense_data_source.dart';
import 'features/dashboard/data/data_sources/dashboard_data_source.dart';
import 'features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'features/breakdown/presentation/cubit/breakdown_cubit.dart';
import 'features/breakdown/data/data_sources/budget_data_source.dart';
import 'features/shell/presentation/screens/shell_screen.dart';
import 'features/shell/presentation/screens/splash_screen.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const MasroufiApp());
}

class MasroufiApp extends StatefulWidget {
  const MasroufiApp({super.key});

  @override
  State<MasroufiApp> createState() => _MasroufiAppState();
}

class _MasroufiAppState extends State<MasroufiApp> {
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _initialization = _initApp();
  }

  Future<void> _initApp() async {
    
    try {
      await Hive.initFlutter();
      await Hive.openBox('pending_expenses');
    } catch (e) {
      debugPrint('Hive init failed: $e');
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      debugPrint('Firebase init skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            title: 'مصروفي',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: const SplashScreen(isInitializing: true),
          );
        }

        
        return MultiRepositoryProvider(
          providers: [
            RepositoryProvider<CategoryDataSource>(create: (_) => CategoryDataSource()),
            RepositoryProvider<ExpenseDataSource>(create: (_) => ExpenseDataSource()),
            RepositoryProvider<AuthDataSource>(
              create: (ctx) => AuthDataSource(
                categoryDataSource: ctx.read<CategoryDataSource>(),
              ),
            ),
            RepositoryProvider<DashboardDataSource>(
              create: (ctx) => DashboardDataSource(
                expenseDataSource: ctx.read<ExpenseDataSource>(),
              ),
            ),
            RepositoryProvider<BudgetDataSource>(create: (_) => BudgetDataSource()),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (ctx) => AuthCubit(
                  authDataSource: ctx.read<AuthDataSource>(),
                ),
              ),
              BlocProvider(
                create: (ctx) => DashboardCubit(
                  dataSource: ctx.read<DashboardDataSource>(),
                  authDataSource: ctx.read<AuthDataSource>(),
                ),
              ),
              BlocProvider(
                create: (ctx) => BreakdownCubit(
                  expenseDataSource: ctx.read<ExpenseDataSource>(),
                  categoryDataSource: ctx.read<CategoryDataSource>(),
                  authDataSource: ctx.read<AuthDataSource>(),
                  budgetDataSource: ctx.read<BudgetDataSource>(),
                ),
              ),
            ],
            child: MaterialApp(
              title: 'مصروفي',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              initialRoute: AppRoutes.splash,
              routes: {
                AppRoutes.splash:    (_) => const SplashScreen(),
                AppRoutes.login:     (_) => const LoginScreen(),
                AppRoutes.register:  (_) => const RegisterScreen(),
                AppRoutes.shell:     (_) => const ShellScreen(),
              },
            ),
          ),
        );
      },
    );
  }
}