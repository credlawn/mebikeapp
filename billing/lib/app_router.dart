import 'package:flutter/material.dart';
import 'screens/dashboard/company_dashboard.dart';
import 'screens/dashboard/dealer_dashboard.dart';
import 'screens/dashboard/subdealer_dashboard.dart';
import 'screens/dashboard/manager_dashboard.dart';
import 'screens/dashboard/account_dashboard.dart';
import 'login_screen.dart';

class AppRouter {
  static Widget getDashboardByRole(String role) {
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
