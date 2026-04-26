import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'app_lock_screen.dart';
import 'setup_pin_screen.dart';
import 'change_password_screen.dart';
import '../../login_screen.dart';
import '../../pb_service.dart';
import '../../services/lock_service.dart';

class FlutterSplashScreen extends StatefulWidget {
  const FlutterSplashScreen({super.key});

  @override
  State<FlutterSplashScreen> createState() => _FlutterSplashScreenState();
}

class _FlutterSplashScreenState extends State<FlutterSplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    _controller.forward();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // Show GIF for at least 3 seconds
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    final record = PbService().pb.authStore.record;
    final bool isAuthenticated = PbService().isAuthenticated;
    final bool needsPasswordChange = record?.getBoolValue('force_password_change') ?? false;
    final bool isPinSet = LockService().isPinSet;

    Widget nextScreen;
    if (!isAuthenticated) {
      nextScreen = const LoginScreen();
    } else if (needsPasswordChange) {
      nextScreen = const ChangePasswordScreen();
    } else if (!isPinSet) {
      nextScreen = const SetupPinScreen();
    } else {
      nextScreen = const AppLockScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/mebike.gif',
                width: MediaQuery.of(context).size.width * 0.8,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
