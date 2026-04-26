import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/partner_provider.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import 'widgets/module_card.dart';
import '../../pb_service.dart';
import '../../login_screen.dart';
import '../partner/partner_list_screen.dart';

class CompanyDashboard extends ConsumerWidget {
  const CompanyDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(allPartnersProvider);
    final activeCount = ref.watch(activePartnersProvider).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () {
              PbService().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                ModuleCard(
                  title: 'Partners',
                  subtitle: partnersAsync.when(
                    data: (list) => '${list.length} Total Registered',
                    loading: () => 'Loading...',
                    error: (_, __) => 'Error loading',
                  ),
                  icon: Icons.people_alt_rounded,
                  color: AppColors.primary,
                  badge: activeCount > 0 ? '$activeCount Active' : null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PartnerListScreen()),
                    );
                  },
                ),
                ModuleCard(
                  title: 'Billing',
                  subtitle: 'Create & Manage Invoices',
                  icon: Icons.receipt_long_rounded,
                  color: Colors.blue,
                  onTap: () => _showComingSoon(context),
                ),
                ModuleCard(
                  title: 'Inventory',
                  subtitle: 'Stock & Warehouse',
                  icon: Icons.inventory_2_rounded,
                  color: Colors.orange,
                  onTap: () => _showComingSoon(context),
                ),
                ModuleCard(
                  title: 'Reports',
                  subtitle: 'Analytics & Insights',
                  icon: Icons.analytics_rounded,
                  color: Colors.purple,
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Module implementation coming soon!')),
    );
  }
}
