import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import 'dashboard_shell.dart';

class DealerDashboard extends StatelessWidget {
  const DealerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      role: 'Dealer',
      color: AppColors.primary,
      icon: Icons.storefront,
    );
  }
}
