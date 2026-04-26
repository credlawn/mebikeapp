import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../../pb_service.dart';
import '../../login_screen.dart';

class DashboardShell extends StatelessWidget {
  final String role;
  final Color color;
  final IconData icon;
  final List<Widget>? actions;
  final Widget? body;

  const DashboardShell({
    super.key,
    required this.role,
    required this.color,
    required this.icon,
    this.actions,
    this.body,
  });

  @override
  Widget build(BuildContext context) {
    final userRecord = PbService().pb.authStore.record;
    final email = userRecord?.getStringValue('email') ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('ME BIKE — $role', style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        actions: [
          ...?actions,
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              PbService().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: body ?? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 20),
            Text('Welcome Back!', style: AppTypography.h1),
            Text(email, style: AppTypography.bodyLarge),
            const SizedBox(height: 20),
            Text('$role Dashboard — Coming Soon', style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }
}
