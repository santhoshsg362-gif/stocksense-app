import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/metrics_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_screen.dart';
import 'services/alert_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AlertService.init();
  final metricsProvider = MetricsProvider();
  await metricsProvider.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => metricsProvider),
      ],
      child: const StockSenseApp(),
    ),
  );
}

class StockSenseApp extends StatelessWidget {
  const StockSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider =
      context.watch<ThemeProvider>();
    final authProvider =
      context.watch<AuthProvider>();

    return MaterialApp(
      title: 'StockSense',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: authProvider.isLoggedIn
        ? const MainScreen()
        : const LoginScreen(),
    );
  }
}