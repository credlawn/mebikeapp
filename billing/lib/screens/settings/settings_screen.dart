import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/company_provider.dart';
import '../../pb_service.dart';
import '../../login_screen.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../company/company_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _handleLogout() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 20),
            Text('Logout', style: AppTypography.h2.copyWith(fontSize: 18)),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to logout?',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    side: BorderSide(color: AppColors.textMuted.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Cancel', style: AppTypography.button.copyWith(color: AppColors.textMuted)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Logout', style: AppTypography.button.copyWith(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true && mounted) {
        PbService().pb.authStore.clear();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader('General'),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.business_outlined,
            iconColor: AppColors.primary,
            title: 'Company Profile',
            subtitle: 'Business name, address, GST, bank details',
            trailing: companyAsync.when(
              data: (company) => company != null ? 'Saved' : 'Not set',
              loading: () => '...',
              error: (_, _) => 'Offline',
            ),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompanyScreen())),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader('Account'),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.person_outline_rounded,
            iconColor: Colors.blue,
            title: 'Profile',
            subtitle: 'Your name, email, role',
            trailing: 'View',
            onTap: () => _showProfileInfo(),
          ),
          const SizedBox(height: 8),
          _buildSettingTile(
            icon: Icons.logout_rounded,
            iconColor: AppColors.error,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: _handleLogout,
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              '© 2026 | Manns Tbi Limited',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileInfo() {
    final user = PbService().pb.authStore.record;
    final name = user?.getStringValue('name') ?? '';
    final email = user?.getStringValue('email') ?? '';
    final role = user?.getStringValue('role') ?? '';
    final mobile = user?.getStringValue('mobile') ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(name.isNotEmpty ? name : 'User', style: AppTypography.h2),
            const SizedBox(height: 8),
            _buildProfileRow('Email', email),
            _buildProfileRow('Role', role.isNotEmpty ? role[0].toUpperCase() + role.substring(1) : '—'),
            if (mobile.isNotEmpty) _buildProfileRow('Mobile', mobile),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Close', style: AppTypography.button.copyWith(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(title, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h3.copyWith(fontSize: 15)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              Text(trailing, style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
