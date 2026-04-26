import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'pb_service.dart';
import 'theme/app_snackbars.dart';
import 'theme/colors.dart';
import 'theme/buttons.dart';
import 'theme/typography.dart';
import 'screens/dashboard/company_dashboard.dart';
import 'screens/dashboard/dealer_dashboard.dart';
import 'screens/dashboard/subdealer_dashboard.dart';
import 'screens/dashboard/manager_dashboard.dart';
import 'screens/dashboard/account_dashboard.dart';
import 'screens/auth/change_password_screen.dart';
import 'services/lock_service.dart';
import 'screens/auth/setup_pin_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _pbService = PbService();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = await _pbService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted) {
        AppSnackBars.showSuccess(context, 'Authentication Successful');
        _navigateByRole(auth.record);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Invalid credentials. Please try again.';
        if (e.toString().contains('message:')) {
          final msg = e.toString().split('message:').last.split(',').first.trim();
          if (msg.isNotEmpty) {
            errorMessage = msg.replaceAll('}', '').replaceAll('"', '').trim();
          }
        }
        AppSnackBars.showError(context, errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateByRole(RecordModel record) {
    final bool needsPasswordChange = record.getBoolValue('force_password_change');
    
    if (needsPasswordChange) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
      );
      return;
    }

    if (!LockService().isPinSet) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SetupPinScreen()),
      );
      return;
    }

    final String role = record.getStringValue('role');
    Widget screen;
    switch (role) {
      case 'company':   screen = const CompanyDashboard(); break;
      case 'dealer':    screen = const DealerDashboard(); break;
      case 'subdealer': screen = const SubDealerDashboard(); break;
      case 'manager':   screen = const ManagerDashboard(); break;
      case 'account':   screen = const AccountDashboard(); break;
      default:
        AppSnackBars.showError(context, 'Unauthorized role.');
        return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          // Left Side - Decorative (Optional for wide screens, but keeps it clean on mobile)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/mebike_logo_final.png',
                          height: 120,
                        ),
                      ),
                      const SizedBox(height: 48),
                      
                      // Welcome Text
                      Text('Account Login', style: AppTypography.h1),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your credentials to access the billing portal',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 40),

                      // Email Field
                      Text('Email Address', style: AppTypography.h3),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        style: AppTypography.input,
                        decoration: _buildInputDecoration(
                          hint: 'name@company.com',
                          icon: Icons.alternate_email_rounded,
                        ),
                        validator: (v) => v!.isEmpty ? 'Email is required' : null,
                      ),
                      const SizedBox(height: 24),

                      // Password Field
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Password', style: AppTypography.h3),
                          TextButton(
                            onPressed: () {}, // Forgot password placeholder
                            child: Text(
                              'Forgot?',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTypography.input,
                        decoration: _buildInputDecoration(
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? 'Password is required' : null,
                      ),
                      const SizedBox(height: 40),

                      // Login Button
                      AppButtons.primary(
                        text: 'Sign In',
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                      ),
                      
                      const SizedBox(height: 32),
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
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
