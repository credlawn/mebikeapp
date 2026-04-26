import 'package:flutter/material.dart';
import '../../pb_service.dart';
import '../../theme/app_snackbars.dart';
import '../../theme/colors.dart';
import '../../theme/buttons.dart';
import '../../theme/typography.dart';
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
        AppSnackBars.showSuccess(context, 'Password updated successfully');
        PbService().logout();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update password. Check old password.';
        if (e.toString().contains('400')) {
          errorMessage = 'Invalid current password or validation error.';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo/Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    Text('Update Security', style: AppTypography.h1),
                    const SizedBox(height: 8),
                    Text(
                      'Please verify your current password and choose a strong new one.',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: 40),

                    // Old Password
                    Text('Current Password', style: AppTypography.h3),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _oldPasswordController,
                      obscureText: _obscureOldPassword,
                      style: AppTypography.input,
                      decoration: _buildInputDecoration(
                        hint: 'Enter current password',
                        icon: Icons.history_toggle_off_rounded,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureOldPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Current password is required' : null,
                    ),
                    const SizedBox(height: 24),

                    // New Password
                    Text('New Password', style: AppTypography.h3),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureNewPassword,
                      style: AppTypography.input,
                      decoration: _buildInputDecoration(
                        hint: 'Min. 8 chars, 1 uppercase, 1 number',
                        icon: Icons.vpn_key_outlined,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                          onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 24),

                    // Confirm Password
                    Text('Confirm Password', style: AppTypography.h3),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureNewPassword,
                      style: AppTypography.input,
                      decoration: _buildInputDecoration(
                        hint: 'Re-type new password',
                        icon: Icons.check_circle_outline_rounded,
                      ),
                      validator: (v) => v!.isEmpty ? 'Confirmation is required' : null,
                    ),
                    const SizedBox(height: 40),

                    // Update Button
                    AppButtons.primary(
                      text: 'Update Password',
                      onPressed: _handleChangePassword,
                      isLoading: _isLoading,
                    ),
                    
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        PbService().logout();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      },
                      child: Center(
                        child: Text(
                          'Cancel & Logout',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
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

  InputDecoration _buildInputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
    _oldPasswordController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
