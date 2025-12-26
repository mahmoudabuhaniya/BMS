import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../db/hive_manager.dart';
import '../theme/app_theme.dart';

import 'beneficiary_form_screen.dart';
import 'beneficiary_list_screen.dart';
import 'deleted_beneficiary_list_screen.dart';
import 'debug_sync_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final sync = Provider.of<SyncService>(context);
    final user = auth.currentUser;
    final pendingCount = HiveManager.queueCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: AppTheme.unicefBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Banner
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.unicefBlue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome,",
                    style: TextStyle(color: Colors.white70),
                  ),
                  Text(
                    "${user?.firstname ?? ''} ${user?.lastname ?? ''}".trim(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sync.isOnline ? "Online" : "Offline",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Sync status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_sync,
                    size: 30,
                    color: pendingCount > 0 ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pendingCount == 0
                          ? "All data is synced"
                          : "Pending items: $pendingCount",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.sync),
                    label: const Text("Sync"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.unicefBlue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Provider.of<SyncService>(
                      context,
                      listen: false,
                    ).manualSync(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _card(
              context,
              "Create Beneficiary",
              Icons.add,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BeneficiaryFormScreen(),
                ),
              ),
            ),
            const SizedBox(height: 15),

            _card(
              context,
              "Beneficiaries List",
              Icons.people,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BeneficiaryListScreen(),
                ),
              ),
            ),
            const SizedBox(height: 15),

            _card(
              context,
              "Deleted Records",
              Icons.delete,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeletedBeneficiaryListScreen(),
                ),
              ),
            ),
            const SizedBox(height: 15),

            _card(
              context,
              "Sync Queue Monitor",
              Icons.settings,
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DebugSyncScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(
    BuildContext context,
    String title,
    IconData icon,
    Function onTap,
  ) {
    return InkWell(
      onTap: () => onTap(),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.unicefBlue.withOpacity(0.13),
              child: Icon(icon, size: 28, color: AppTheme.unicefBlue),
            ),
            const SizedBox(width: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
