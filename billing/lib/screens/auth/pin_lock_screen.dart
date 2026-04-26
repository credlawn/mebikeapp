import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import '../../services/lock_service.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../app_router.dart';
import '../../pb_service.dart';
import '../../login_screen.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final _pinController = TextEditingController();
  final _lockService = LockService();

  void _handlePinSubmit(String pin) {
    if (_lockService.verifyPin(pin)) {
      final record = PbService().pb.authStore.record;
      final String role = record?.getStringValue('role') ?? '';
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => AppRouter.getDashboardByRole(role)),
        (route) => false,
      );
    } else {
      AppSnackBars.showError(context, 'Incorrect PIN');
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primary),
            onPressed: () => SystemNavigator.pop(),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security_rounded, size: 80, color: AppColors.primary),
                  const SizedBox(height: 32),
                  Text('Enter App PIN', style: AppTypography.h1),
                  const SizedBox(height: 12),
                  Text('Verify your identity to continue', style: AppTypography.bodyMedium),
                  const SizedBox(height: 48),
                  Pinput(
                    length: 4,
                    controller: _pinController,
                    defaultPinTheme: PinTheme(
                      width: 56,
                      height: 56,
                      textStyle: AppTypography.h1.copyWith(color: AppColors.primary),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                    ),
                    onCompleted: _handlePinSubmit,
                    autofocus: true,
                    obscureText: true,
                  ),
                  const SizedBox(height: 64),
                  TextButton(
                    onPressed: () {
                      PbService().logout();
                      _lockService.clearPin();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    },
                    child: Text('Logout & Reset', style: TextStyle(color: Colors.red.shade400)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
