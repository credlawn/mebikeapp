import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/lock_service.dart';
import '../../pb_service.dart';
import '../../login_screen.dart';
import '../../services/preloader_service.dart';
import 'app_lock_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final lockService = LockService();
    final pbService = PbService();

    // 1. Minimum delay for the animation to look good
    final animationDelay = Future.delayed(const Duration(seconds: 3));

    // 2. Pre-fetch all data in the background
    // This happens while the GIF is playing
    final dataFetching = PreloaderService.preloadAppData(ref);

    // 3. Check Auth Status
    final bool isLoggedIn = pbService.pb.authStore.isValid;

    // 4. Wait for both animation and critical data fetching to complete
    await Future.wait([animationDelay, dataFetching]);

    if (!mounted) return;

    if (isLoggedIn) {
      // If logged in, go to Lock Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppLockScreen()),
      );
    } else {
      // Otherwise go to Login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/mebike.gif',
              width: 300,
              height: 300,
            ),
          ],
        ),
      ),
    );
  }
}
