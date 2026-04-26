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

enum _LockState { waiting, showPin, success }

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startBiometric());
  }

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
        setState(() => _state = _LockState.success);
        await Future.delayed(const Duration(seconds: 1));
        _unlock();
      } else {
        // User tapped "Use PIN"
        setState(() => _state = _LockState.showPin);
      }
    } catch (e) {
      if (mounted) setState(() => _state = _LockState.showPin);
    } finally {
      _isAuthRunning = false;
    }
  }

  void _handlePinSubmit(String pin) {
    if (_lockService.verifyPin(pin)) {
      _unlock();
    } else {
      AppSnackBars.showError(context, 'Incorrect PIN');
      _pinController.clear();
    }
  }

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
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _LockState.waiting:
        return const SizedBox.shrink(); // Clean white, popup on top

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
