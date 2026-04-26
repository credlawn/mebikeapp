import 'package:flutter/material.dart';
import 'dashboard_shell.dart';

class AccountDashboard extends StatelessWidget {
  const AccountDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const DashboardShell(
      role: 'Account',
      color: Colors.orange,
      icon: Icons.account_balance,
    );
  }
}
