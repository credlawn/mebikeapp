import 'package:flutter/material.dart';
import 'dashboard_shell.dart';

class CompanyDashboard extends StatelessWidget {
  const CompanyDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      role: 'Company',
      color: Colors.purple,
      icon: Icons.business,
    );
  }
}
