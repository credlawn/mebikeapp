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
  final _lockService = LockService();

  void _handlePinSubmit(String pin) async {
    if (!widget.isConfirming) {
      // Go to confirmation
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SetupPinScreen(isConfirming: true, firstPin: pin),
        ),
      );
    } else {
      // Verify confirmation
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
          title: const Text('Enable Fingerprint?'),
          content: const Text('Would you like to use fingerprint to unlock the app quickly?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _finishSetup();
              },
              child: const Text('NO'),
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
                    AppSnackBars.showError(context, 'Biometric verification failed.');
                  }
                }
              },
              child: const Text('YES'),
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
      width: 56,
      height: 56,
      textStyle: AppTypography.h1.copyWith(color: AppColors.primary),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Setup App Lock'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline_rounded, size: 80, color: AppColors.primary),
              const SizedBox(height: 32),
              Text(
                widget.isConfirming ? 'Confirm your PIN' : 'Create a 4-digit PIN',
                style: AppTypography.h1,
              ),
              const SizedBox(height: 12),
              Text(
                'This PIN will be used to unlock your app.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Pinput(
                length: 4,
                controller: _pinController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                ),
                onCompleted: _handlePinSubmit,
                autofocus: true,
                obscureText: true,
              ),
              const SizedBox(height: 48),
              if (widget.isConfirming)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
