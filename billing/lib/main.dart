import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'login_screen.dart';
import 'theme/colors.dart';
import 'pb_service.dart';
import 'screens/dashboard/company_dashboard.dart';
import 'screens/dashboard/dealer_dashboard.dart';
import 'screens/dashboard/subdealer_dashboard.dart';
import 'screens/dashboard/manager_dashboard.dart';
import 'screens/dashboard/account_dashboard.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await PbService().init();
  } catch (e) {
    if (kDebugMode) print('❌ Initialization Error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ME BIKE Billing',
      navigatorKey: PbService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      ),
      home: PbService().isAuthenticated 
          ? _getDashboard(PbService().pb.authStore.record?.getStringValue('role') ?? '')
          : const LoginScreen(),
    );
  }

  Widget _getDashboard(String role) {
    switch (role) {
      case 'company':   return const CompanyDashboard();
      case 'dealer':    return const DealerDashboard();
      case 'subdealer': return const SubDealerDashboard();
      case 'manager':   return const ManagerDashboard();
      case 'account':   return const AccountDashboard();
      default:          return const LoginScreen();
    }
  }
}
