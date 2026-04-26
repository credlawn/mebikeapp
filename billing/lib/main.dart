import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'login_screen.dart';
import 'theme/colors.dart';
import 'pb_service.dart';
import 'screens/auth/change_password_screen.dart';
import 'services/lock_service.dart';
import 'screens/auth/setup_pin_screen.dart';
import 'screens/auth/app_lock_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await PbService().init();
    await LockService().init();
  } catch (e) {
    if (kDebugMode) print('❌ Initialization Error: $e');
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final lockService = LockService();
    final pbService = PbService();

    if (state == AppLifecycleState.paused) {
      // App went to background — save timestamp
      lockService.onAppBackgrounded();
    } else if (state == AppLifecycleState.resumed) {
      // App came to foreground
      if (pbService.isAuthenticated && lockService.isPinSet) {
        if (lockService.shouldLockOnResume) {
          // 15 minutes exceeded — lock the app
          lockService.onAppForegrounded();
          PbService.navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AppLockScreen()),
            (route) => false,
          );
        } else {
          // Within 15 minutes — clear background timestamp, no lock
          lockService.onAppForegrounded();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ME BIKE Billing',
      navigatorKey: PbService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const FlutterSplashScreen(),
    );
  }
}
