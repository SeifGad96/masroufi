import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_routes.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/categories/data/repositories/category_repository.dart';
import 'features/expenses/data/repositories/expense_repository.dart';
import 'features/dashboard/data/repositories/dashboard_repository.dart';
import 'features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'features/breakdown/presentation/cubit/breakdown_cubit.dart';
import 'features/shell/presentation/screens/shell_screen.dart';
import 'features/shell/presentation/screens/splash_screen.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Transparent status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Initialize Hive
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

  runApp(const MasroufiApp());
}

class MasroufiApp extends StatelessWidget {
  const MasroufiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => CategoryRepository()),
        RepositoryProvider(create: (_) => ExpenseRepository()),
        RepositoryProvider(
          create: (ctx) => AuthRepository(
            categoryRepository: ctx.read<CategoryRepository>(),
          ),
        ),
        RepositoryProvider(
          create: (ctx) => DashboardRepository(
            expenseRepository: ctx.read<ExpenseRepository>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (ctx) => AuthCubit(
              authRepository: ctx.read<AuthRepository>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => DashboardCubit(
              repository: ctx.read<DashboardRepository>(),
              authRepository: ctx.read<AuthRepository>(),
            ),
          ),
          BlocProvider(
            create: (ctx) => BreakdownCubit(
              expenseRepository: ctx.read<ExpenseRepository>(),
              categoryRepository: ctx.read<CategoryRepository>(),
              authRepository: ctx.read<AuthRepository>(),
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
  }
}
