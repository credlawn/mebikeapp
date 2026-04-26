import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'login_screen.dart';
import 'theme/colors.dart';
import 'pb_service.dart';
import 'screens/auth/change_password_screen.dart';
import 'services/lock_service.dart';
import 'screens/auth/setup_pin_screen.dart';
import 'screens/auth/app_lock_screen.dart';
import 'app_router.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await PbService().init();
    await LockService().init();
  } catch (e) {
    if (kDebugMode) print('❌ Initialization Error: $e');
  }
  runApp(const MyApp());
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
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: _getInitialScreen(),
    );
  }

  Widget _getInitialScreen() {
    final record = PbService().pb.authStore.record;
    final bool isAuthenticated = PbService().isAuthenticated;
    final bool needsPasswordChange = record?.getBoolValue('force_password_change') ?? false;
    final bool isPinSet = LockService().isPinSet;

    if (!isAuthenticated) return const LoginScreen();
    if (needsPasswordChange) return const ChangePasswordScreen();
    if (!isPinSet) return const SetupPinScreen();
    return const AppLockScreen();
  }
}
