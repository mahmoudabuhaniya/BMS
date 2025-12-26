import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

import 'home_screen.dart';
import 'profile_screen.dart';
import 'queue_monitor_screen.dart';
import 'sync_log_screen.dart';
import 'about_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static _MainShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainShellState>();
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  Widget build(BuildContext context) {
    final sync = Provider.of<SyncService>(context);

    return Scaffold(
      // ---------------------------------------
      // DRAWER
      // ---------------------------------------
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppTheme.unicefBlue),
              accountName: Text(AuthService.currentUserStatic?.fullName ?? ""),
              accountEmail: Text(AuthService.currentUserStatic?.email ?? ""),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: AppTheme.unicefBlue, size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_upload),
              title: const Text("Queue Monitor"),
              trailing: sync.isSyncing
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QueueMonitorScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text("Sync Log"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SyncLogScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("About App"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                await Provider.of<AuthService>(context, listen: false).logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, "/login");
              },
            ),
          ],
        ),
      ),

      // ---------------------------------------
      // APP BAR (for all pages rendered inside MainShell)
      // ---------------------------------------
      appBar: AppBar(
        backgroundColor: AppTheme.unicefBlue,
        title: const Text("BMS Mobile App",
            style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.white,
      ),

      // ---------------------------------------
      // BODY → Always HomeScreen
      // ---------------------------------------
      body: const HomeScreen(),

      // ---------------------------------------
      // UNICEF BLUE FOOTER BAR
      // ---------------------------------------
      bottomNavigationBar: Container(
        height: 55,
        decoration: const BoxDecoration(
          color: AppTheme.unicefBlue,
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                "UNICEF BMS Mobile App",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
