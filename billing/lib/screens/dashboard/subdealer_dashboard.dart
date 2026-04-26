import 'package:flutter/material.dart';
import 'dashboard_shell.dart';

class SubDealerDashboard extends StatelessWidget {
  const SubDealerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      role: 'Sub Dealer',
      color: Colors.teal,
      icon: Icons.store,
    );
  }
}
