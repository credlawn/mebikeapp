import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../services/lock_service.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/buttons.dart';
import '../../theme/typography.dart';
import '../../app_router.dart';
import '../../pb_service.dart';

class SetupPinScreen extends StatefulWidget {
  final bool isConfirming;
  final String? firstPin;

  const SetupPinScreen({
    super.key,
    this.isConfirming = false,
    this.firstPin,
  });

  @override
  State<SetupPinScreen> createState() => _SetupPinScreenState();
}

class _SetupPinScreenState extends State<SetupPinScreen> {
  final _pinController = TextEditingController();
  final _pinFocusNode = FocusNode();
  final _lockService = LockService();

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  void _handlePinSubmit(String pin) async {
    if (!widget.isConfirming) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              SetupPinScreen(isConfirming: true, firstPin: pin),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ).then((_) {
        _pinController.clear();
        _pinFocusNode.requestFocus();
      }); 
    } else {
      if (pin == widget.firstPin) {
        await _lockService.setPin(pin);
        if (mounted) {
          _showBiometricDialog();
        }
      } else {
        AppSnackBars.showError(context, 'PINs do not match. Try again.');
        _pinController.clear();
      }
    }
  }

  void _showBiometricDialog() async {
    final canBio = await _lockService.canCheckBiometrics();
    if (!mounted) return;

    if (canBio) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Enable Biometrics?', style: AppTypography.h3),
          content: Text(
            'Would you like to use fingerprint to unlock the app quickly?',
            style: AppTypography.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _finishSetup();
              },
              child: Text('NO', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                final verified = await _lockService.authenticateWithBiometrics(ignoreEnabledFlag: true);
                if (verified) {
                  await _lockService.setBiometricEnabled(true);
                  if (mounted) {
                    Navigator.of(context).pop();
                    _finishSetup();
                  }
                } else {
                  if (mounted) {
                    AppSnackBars.showError(context, 'Verification failed.');
                  }
                }
              },
              child: const Text('YES', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else {
      _finishSetup();
    }
  }

  void _finishSetup() {
    final record = PbService().pb.authStore.record;
    final String role = record?.getStringValue('role') ?? '';

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AppRouter.getDashboardByRole(role)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 60,
      height: 64,
      textStyle: AppTypography.h1.copyWith(color: AppColors.primary),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              
              Text(
                widget.isConfirming ? 'Confirm PIN' : 'Create App PIN',
                style: AppTypography.h1,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isConfirming 
                    ? 'Verify your new 4-digit PIN to secure your account.'
                    : 'Set a 4-digit security PIN to protect your billing data.',
                style: AppTypography.bodyMedium,
              ),
              
              const Spacer(),
              
              Center(
                child: Pinput(
                  length: 4,
                  controller: _pinController,
                  focusNode: _pinFocusNode,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: defaultPinTheme.copyWith(
                    decoration: defaultPinTheme.decoration!.copyWith(
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                  ),
                  onCompleted: _handlePinSubmit,
                  autofocus: true,
                  obscureText: true,
                ),
              ),
              
              const Spacer(flex: 2),
              
              if (widget.isConfirming)
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Reset pin again',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '© 2026 | Manns Tbi Limited',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
