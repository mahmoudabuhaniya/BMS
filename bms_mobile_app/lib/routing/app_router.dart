import 'package:flutter/material.dart';

import '../services/auth_service.dart';

// SCREENS
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/home_screen.dart';
import '../screens/beneficiary_form_screen.dart';
import '../screens/beneficiary_list_screen.dart';
import '../screens/deleted_beneficiary_list_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/queue_monitor_screen.dart';
import '../screens/sync_log_screen.dart';
import '../screens/about_screen.dart';

class AppRouter {
  static String initialRoute(AuthService auth) {
    return auth.isLoggedIn ? "/shell" : "/login";
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case "/login":
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      // 🔥 MAIN SHELL (Drawer + Bottom Nav + All pages)
      case "/shell":
        return MaterialPageRoute(builder: (_) => const MainShell());

      // DIRECT PAGES (optional)
      case "/home":
        return MaterialPageRoute(builder: (_) => const MainShell());
      case "/add":
        return MaterialPageRoute(builder: (_) => const BeneficiaryFormScreen());
      case "/list":
        return MaterialPageRoute(builder: (_) => const BeneficiaryListScreen());
      case "/deleted":
        return MaterialPageRoute(
            builder: (_) => const DeletedBeneficiaryListScreen());
      case "/profile":
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case "/queue":
        return MaterialPageRoute(builder: (_) => const QueueMonitorScreen());
      case "/sync_log":
        return MaterialPageRoute(builder: (_) => const SyncLogScreen());
      case "/about":
        return MaterialPageRoute(builder: (_) => const AboutScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text("404 – Page not found")),
          ),
        );
    }
  }
}
