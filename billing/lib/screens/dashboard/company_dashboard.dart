import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/partner_provider.dart';
import '../../providers/connectivity_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../theme/app_snackbars.dart';
import '../../pb_service.dart';
import '../../login_screen.dart';

class CompanyDashboard extends ConsumerStatefulWidget {
  const CompanyDashboard({super.key});

  @override
  ConsumerState<CompanyDashboard> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends ConsumerState<CompanyDashboard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    try {
      await ref.refresh(allPartnersProvider.future).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw 'Server timeout. Try again later.',
      );
      if (mounted) AppSnackBars.showSuccess(context, 'Data updated');
    } catch (e) {
      if (mounted) AppSnackBars.showError(context, e.toString());
    }
  }

  void _handleLogout() {
    PbService().pb.authStore.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(allPartnersProvider);
    final connectivityAsync = ref.watch(connectivityProvider);
    
    final activePartners = ref.watch(activePartnersProvider);
    final inactivePartners = ref.watch(inactivePartnersProvider);
    final totalRegisteredCount = activePartners.length + inactivePartners.length;
    final activeCount = activePartners.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Dashboard'),
            const SizedBox(width: 12),
            _buildStatusIndicator(connectivityAsync.value ?? ConnectivityStatus.checking),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.primary,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Management Modules'),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: [
                  ModuleCard(
                    title: 'Partners',
                    subtitle: partnersAsync.when(
                      data: (_) => '$totalRegisteredCount Total Registered',
                      loading: () => 'Syncing partners...',
                      error: (_, __) => 'Offline mode',
                    ),
                    icon: Icons.people_alt_rounded,
                    color: AppColors.primary,
                    badge: activeCount > 0 ? '$activeCount Active' : null,
                    onTap: () => Navigator.pushNamed(context, '/partner-list'),
                  ),
                  const ModuleCard(
                    title: 'Inventory',
                    subtitle: 'Stock & Items',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.blue,
                  ),
                  const ModuleCard(
                    title: 'Billing',
                    subtitle: 'Invoices & Tax',
                    icon: Icons.receipt_long_outlined,
                    color: Colors.orange,
                  ),
                  const ModuleCard(
                    title: 'Reports',
                    subtitle: 'Analytics',
                    icon: Icons.analytics_outlined,
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildSectionHeader('Recent Activity'),
              const SizedBox(height: 16),
              _buildActivityPlaceholder(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(ConnectivityStatus status) {
    final isOnline = status == ConnectivityStatus.online;
    final color = isOnline ? AppColors.primary : Colors.grey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _pulseController,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isOnline ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4, spreadRadius: 1)] : null,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : (status == ConnectivityStatus.checking ? 'Checking' : 'Offline'),
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: AppTypography.h2);
  }

  Widget _buildActivityPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text('No recent activities found', style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? badge;
  final VoidCallback? onTap;

  const ModuleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(title, style: AppTypography.h3),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (badge != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
