import 'package:flutter/material.dart';
import '../../pb_service.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/buttons.dart';
import '../../theme/typography.dart';
import '../../main.dart';
import '../../login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[A-Z]'))) return 'Must contain at least 1 uppercase letter';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Must contain at least 1 number';
    return null;
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      AppSnackBars.showError(context, 'New passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = PbService().pb.authStore.record?.id;
      if (userId == null) throw 'User session not found';

      await PbService().pb.collection('users').update(userId, body: {
        'oldPassword': _oldPasswordController.text.trim(),
        'password': _passwordController.text.trim(),
        'passwordConfirm': _confirmPasswordController.text.trim(),
        'force_password_change': false,
      });

      if (mounted) {
        AppSnackBars.showSuccess(context, 'Password changed! Please login with your new password.');
        
        // Clear session and go back to Login
        PbService().logout();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('400')) {
          errorMessage = 'Invalid old password or validation failed.';
        }
        AppSnackBars.showError(context, errorMessage);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Security Update'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_reset_rounded, size: 64, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text('Change Password', style: AppTypography.h1, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    Text('Please verify your old password and set a new one.', style: AppTypography.bodyMedium, textAlign: TextAlign.center),
                    const SizedBox(height: 32),
                    
                    // Old Password Field
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: _obscureOldPassword,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.history_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureOldPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Enter current password' : null,
                    ),
                    const SizedBox(height: 20),

                    // New Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 20),

                    // Confirm Password Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureNewPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.check_circle_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Confirm your new password' : null,
                    ),
                    const SizedBox(height: 40),

                    AppButtons.primary(
                      text: 'UPDATE PASSWORD',
                      onPressed: _handleChangePassword,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
