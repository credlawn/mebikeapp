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
  final _pinFocusNode = FocusNode();
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
      _pinFocusNode.requestFocus();

      if (_lockService.isLockedOut) {
        AppSnackBars.showError(context, 'Too many attempts. Cooldown active.');
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
        setState(() {
          _state = _LockState.showPin;
          WidgetsBinding.instance.addPostFrameCallback((_) => _pinFocusNode.requestFocus());
        });
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
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pinController.dispose();
    _pinFocusNode.dispose();
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, size: 64, color: AppColors.success),
              ),
              const SizedBox(height: 24),
              Text(
                'Authenticated',
                style: AppTypography.h2.copyWith(color: AppColors.success),
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_clock_rounded, size: 48, color: AppColors.primary),
                ),
                const SizedBox(height: 32),
                Text('Temporary Lockout', style: AppTypography.h1),
                const SizedBox(height: 12),
                Text(
                  'Too many failed attempts.\nPlease try again in a few moments.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 100,
                  height: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: _remainingSeconds / LockService.cooldownSeconds,
                        strokeWidth: 4,
                        color: AppColors.primary,
                        backgroundColor: AppColors.primaryLight,
                      ),
                      Center(
                        child: Text(
                          '$_remainingSeconds',
                          style: AppTypography.h1.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 64),
                TextButton(
                  onPressed: _handleLogout,
                  child: Text(
                    'Logout & Reset',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case _LockState.showPin:
        final defaultPinTheme = PinTheme(
          width: 56,
          height: 60,
          textStyle: AppTypography.h1.copyWith(color: AppColors.primary),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
        );

        return SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/mebike_logo_final.png', height: 80),
                  const SizedBox(height: 48),
                  Text('Enter App PIN', style: AppTypography.h2),
                  const SizedBox(height: 8),
                  Text('Secure Access Required', style: AppTypography.bodySmall),
                  const SizedBox(height: 40),
                  Pinput(
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
                  const SizedBox(height: 40),
                  if (_lockService.isBiometricEnabled)
                    TextButton.icon(
                      onPressed: () {
                        _pinController.clear();
                        setState(() => _state = _LockState.waiting);
                        _startBiometric();
                      },
                      icon: const Icon(Icons.fingerprint_rounded, size: 20),
                      label: const Text('Use Biometrics'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  const SizedBox(height: 64),
                  TextButton(
                    onPressed: _handleLogout,
                    child: Text(
                      'Logout & Reset Account',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '© 2026 | Manns Tbi Limited',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }
}
