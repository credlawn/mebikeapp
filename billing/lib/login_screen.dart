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
        AppSnackBars.showSuccess(context, 'Welcome back!');
        _navigateByRole(auth.record);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Authentication failed. Please check your credentials.';
        if (e.toString().contains('message:')) {
          final msg = e.toString().split('message:').last.split(',').first.trim();
          if (msg.isNotEmpty) {
            errorMessage = msg
                .replaceAll('}', '')
                .replaceAll('"', '')
                .replaceAll('[FORCED_LOGOUT]', '')
                .trim();
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

    final String role = record.getStringValue('role');
    Widget screen;
    switch (role) {
      case 'company':   screen = const CompanyDashboard(); break;
      case 'dealer':    screen = const DealerDashboard(); break;
      case 'subdealer': screen = const SubDealerDashboard(); break;
      case 'manager':   screen = const ManagerDashboard(); break;
      case 'account':   screen = const AccountDashboard(); break;
      default:
        AppSnackBars.showError(context, 'Unknown role. Contact support.');
        return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.primaryGradient,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 12,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.lock_person_rounded,
                        size: 80,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Welcome Back',
                        style: AppTypography.h1,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login to your account',
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      AppButtons.primary(
                        text: 'LOGIN',
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
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
