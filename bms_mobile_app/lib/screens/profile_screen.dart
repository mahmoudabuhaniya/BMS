import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final sync = Provider.of<SyncService>(context);
    final user = auth.currentUser;

    // ------------------------------
    // FIXED: Proper full name logic
    // ------------------------------
    final fullName = (user?.fullName?.trim().isNotEmpty == true)
        ? user!.fullName!
        : user?.username ?? "User";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.unicefBlue,
        title: const Text("My Profile"),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // HEADER CARD
            // --------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.unicefBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 48),
                  const SizedBox(height: 10),

                  // Name
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    user?.fullName ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    user?.email ?? "",
                    style: const TextStyle(color: Colors.white70),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Groups: ${user?.groups ?? "-"}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --------------------------------------------------
            // ONLINE STATUS
            // --------------------------------------------------
            Row(
              children: [
                Icon(
                  sync.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: sync.isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 10),
                Text(
                  sync.isOnline ? "Online" : "Offline",
                  style: TextStyle(
                    fontSize: 16,
                    color: sync.isOnline ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // LAST SYNC TIME (FIXED)
            // --------------------------------------------------
            Text(
              "Last Sync: ${sync.lastSyncTime != null ? sync.lastSyncTime!.toLocal().toString().split('.').first : 'Never'}",
              style: const TextStyle(fontSize: 15),
            ),

            const Divider(height: 32),

            // --------------------------------------------------
            // SYNC BUTTON
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.sync),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.unicefBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                label: Text(
                  sync.isSyncing ? "Syncing..." : "Sync Now",
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: sync.isSyncing ? null : () => sync.manualSync(),
              ),
            ),

            const SizedBox(height: 12),

            // --------------------------------------------------
            // LOGOUT BUTTON
            // --------------------------------------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                label: const Text(
                  "Logout",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/login",
                      (_) => false,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
