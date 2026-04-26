import 'package:flutter/material.dart';
import 'dashboard_shell.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      role: 'Manager',
      color: Colors.green,
      icon: Icons.manage_accounts,
    );
  }
}
