import 'dart:async';
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

enum _LockState { waiting, showPin, cooldown, success }

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _pinController = TextEditingController();
  final _lockService = LockService();
  _LockState _state = _LockState.waiting;
  bool _isAuthRunning = false;
  int _remainingSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_lockService.isLockedOut) {
        _startCooldownTimer();
      } else {
        _startBiometric();
      }
    });
  }

  // ─── Biometric ─────────────────────────────────────────────────────────

  Future<void> _startBiometric() async {
    if (_isAuthRunning) return;
    if (!_lockService.isBiometricEnabled) {
      if (mounted) setState(() => _state = _LockState.showPin);
      return;
    }

    _isAuthRunning = true;
    try {
      final authenticated = await _lockService.authenticateWithBiometrics();
      if (!mounted) return;

      if (authenticated) {
        await _lockService.resetFailedAttempts();
        setState(() => _state = _LockState.success);
        await Future.delayed(const Duration(seconds: 1));
        _unlock();
      } else {
        setState(() => _state = _LockState.showPin);
      }
    } catch (e) {
      if (mounted) setState(() => _state = _LockState.showPin);
    } finally {
      _isAuthRunning = false;
    }
  }

  // ─── PIN ───────────────────────────────────────────────────────────────

  Future<void> _handlePinSubmit(String pin) async {
    if (_lockService.isLockedOut) {
      _startCooldownTimer();
      return;
    }

    if (_lockService.verifyPin(pin)) {
      await _lockService.resetFailedAttempts();
      _unlock();
    } else {
      await _lockService.recordFailedAttempt();
      _pinController.clear();

      if (_lockService.isLockedOut) {
        AppSnackBars.showError(context, 'Too many attempts. Please wait 30 seconds.');
        _startCooldownTimer();
      } else {
        final remaining = LockService.maxFailedAttempts - _lockService.failedAttempts;
        AppSnackBars.showError(context, 'Incorrect PIN. $remaining attempt(s) left.');
      }
    }
  }

  // ─── Cooldown ──────────────────────────────────────────────────────────

  void _startCooldownTimer() {
    setState(() {
      _state = _LockState.cooldown;
      _remainingSeconds = _lockService.remainingCooldownSeconds;
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      final remaining = _lockService.remainingCooldownSeconds;
      if (remaining <= 0) {
        timer.cancel();
        setState(() => _state = _LockState.showPin);
      } else {
        setState(() => _remainingSeconds = remaining);
      }
    });
  }

  // ─── Navigation ────────────────────────────────────────────────────────

  void _unlock() {
    if (!mounted) return;
    final role = PbService().pb.authStore.record?.getStringValue('role') ?? '';
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AppRouter.getDashboardByRole(role)),
      (route) => false,
    );
  }

  void _handleLogout() {
    PbService().logout();
    _lockService.clearPin();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => SystemNavigator.pop(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _LockState.waiting:
        return const SizedBox.shrink();

      case _LockState.success:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                'Successfully Authenticated',
                style: AppTypography.bodyMedium.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case _LockState.cooldown:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_clock_rounded, size: 80, color: Colors.orange),
                const SizedBox(height: 24),
                Text('Too Many Attempts', style: AppTypography.h1),
                const SizedBox(height: 12),
                Text(
                  'Please wait $_remainingSeconds seconds before trying again.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _remainingSeconds / LockService.cooldownSeconds,
                        strokeWidth: 6,
                        color: Colors.orange,
                        backgroundColor: Colors.orange.shade100,
                      ),
                      Center(
                        child: Text(
                          '$_remainingSeconds',
                          style: AppTypography.h1.copyWith(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 64),
                TextButton(
                  onPressed: _handleLogout,
                  child: Text('Logout & Reset', style: TextStyle(color: Colors.red.shade400)),
                ),
              ],
            ),
          ),
        );

      case _LockState.showPin:
        return SafeArea(
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
                  const SizedBox(height: 32),
                  if (_lockService.isBiometricEnabled)
                    TextButton(
                      onPressed: () {
                        _pinController.clear();
                        setState(() => _state = _LockState.waiting);
                        _startBiometric();
                      },
                      child: const Text('Use Fingerprint Instead'),
                    ),
                  const SizedBox(height: 32),
                  TextButton(
                    onPressed: _handleLogout,
                    child: Text('Logout & Reset', style: TextStyle(color: Colors.red.shade400)),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}
