import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

import 'beneficiary_form_screen.dart';
import 'beneficiary_list_screen.dart';
import 'deleted_beneficiary_list_screen.dart';
import 'queue_monitor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final sync = Provider.of<SyncService>(context);

    final fullname =
        "${auth.currentUser?.firstname ?? ''} ${auth.currentUser?.lastname ?? ''}"
            .trim();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.unicefBlue,
        title: const Text("Beneficiary Management System"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // --------------------------------------------------------
            // HEADER BLOCK WITH SYNC BAR
            // --------------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.unicefBlue,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                    child: Image.asset("assets/unicef_logo.png"),
                  ),
                  const SizedBox(height: 10),

                  const Text("Welcome",
                      style: TextStyle(color: Colors.white70, fontSize: 18)),

                  Text(
                    fullname,
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ⭐ SYNC PROGRESS BAR
                  LinearProgressIndicator(
                    value: sync.isSyncing ? sync.progress / 100 : 1,
                    minHeight: 6,
                    color: sync.isSyncing ? Colors.orange : Colors.greenAccent,
                    backgroundColor: Colors.white24,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    sync.isSyncing
                        ? "Syncing… ${sync.progressPercent}%"
                        : "Last Sync: ${sync.lastSyncTime ?? '-'}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --------------------------------------------------------
            // BUTTONS
            // --------------------------------------------------------
            _btn(
              title: "Add New Beneficiary",
              icon: Icons.person_add_alt_1,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BeneficiaryFormScreen(),
                ),
              ),
            ),
            const SizedBox(height: 15),

            _btn(
              title: "View All Beneficiaries",
              icon: Icons.people_alt_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BeneficiaryListScreen(),
                ),
              ),
            ),
            const SizedBox(height: 15),

            _btn(
              title: "Deleted Records",
              icon: Icons.delete_forever,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DeletedBeneficiaryListScreen(),
                ),
              ),
            ),
            const SizedBox(height: 15),

            _btn(
              title: "Sync Queue Monitor",
              icon: Icons.bug_report_rounded,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const QueueMonitorScreen(),
                ),
              ),
            ),
            const SizedBox(height: 15),

            _btn(
              title: sync.isSyncing ? "Syncing…" : "Sync Now",
              icon: Icons.sync,
              onTap: () => sync.manualSync(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn({
    required String title,
    required IconData icon,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(horizontal: 25),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(icon, size: 32, color: AppTheme.unicefBlue),
            ),
            const SizedBox(width: 22),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
