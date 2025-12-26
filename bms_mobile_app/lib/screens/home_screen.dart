import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/hive_manager.dart';
import '../models/beneficiary.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_started) {
        _started = true;
        context.read<SyncService>().manualSync();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncService>();
    final user = AuthService.currentUserStatic;

    // ------------------------------------------------
    // OFFLINE SAFE COUNTS
    // ------------------------------------------------
    final List<Beneficiary> all = HiveManager.getAll();
    final myItems = all.where((b) => b.createdBy == user?.username).toList();
    final deleted = all.where((b) => b.deleted == true).toList();

    final totalCount = all.length;
    final myCount = myItems.length;
    final deletedCount = deleted.length;
    final queueCount = HiveManager.getQueue().length;

    final username = (user?.fullName?.trim().isNotEmpty == true)
        ? user!.fullName!
        : user?.username ?? "User";

    return RefreshIndicator(
      onRefresh: sync.manualSync,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ------------------------------------------------
          // WELCOME
          // ------------------------------------------------
          Text(
            "Welcome, $username",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.unicefBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Your offline/online beneficiary management dashboard",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),

          const SizedBox(height: 20),

          // ------------------------------------------------
          // STATUS CARD
          // ------------------------------------------------
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        sync.isOnline ? Icons.wifi : Icons.wifi_off,
                        color: sync.isOnline ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        sync.isOnline ? "Online" : "Offline Mode",
                        style: TextStyle(
                          color: sync.isOnline ? Colors.green : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.unicefBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        icon: const Icon(Icons.sync, color: Colors.white),
                        label: Text(
                          sync.isSyncing ? "Syncing..." : "Sync Now",
                          style: const TextStyle(color: Colors.white),
                        ),
                        onPressed: sync.isSyncing ? null : sync.manualSync,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Last sync: ${sync.lastSyncTime != null ? sync.lastSyncTime!.toLocal().toString().split('.').first : 'Never'}",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  if (sync.isSyncing)
                    LinearProgressIndicator(
                      value: sync.progress / 100,
                      backgroundColor: Colors.grey.shade300,
                      color: AppTheme.unicefBlue,
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------
          // COUNTERS
          // ------------------------------------------------
          Row(
            children: [
              Expanded(child: _counterCard("Total", totalCount, Icons.people)),
              const SizedBox(width: 12),
              Expanded(child: _counterCard("Mine", myCount, Icons.person)),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _counterCard("Pending", queueCount, Icons.cloud_upload),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _counterCard("Deleted", deletedCount, Icons.delete),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // ------------------------------------------------
          // QUICK ACTIONS
          // ------------------------------------------------
          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _quickActionsGrid(context),
        ],
      ),
    );
  }

  // ------------------------------------------------
  // QUICK ACTIONS GRID
  // ------------------------------------------------
  Widget _quickActionsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 36) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _quickButton(context,
                label: "Add New",
                icon: Icons.add_circle_outline,
                width: tileWidth,
                route: "/add"),
            _quickButton(context,
                label: "All Beneficiaries",
                icon: Icons.list_alt,
                width: tileWidth,
                route: "/list"),
            _quickButton(context,
                label: "Deleted Items",
                icon: Icons.delete_outline,
                width: tileWidth,
                route: "/deleted"),
            _quickButton(context,
                label: "Queue Monitor",
                icon: Icons.cloud_upload,
                width: tileWidth,
                route: "/queue"),
          ],
        );
      },
    );
  }

  Widget _quickButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required double width,
    required String route,
  }) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.unicefBlue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.unicefBlue.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppTheme.unicefBlue),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _counterCard(String label, int count, IconData icon) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(icon, size: 30, color: AppTheme.unicefBlue),
            const SizedBox(height: 10),
            Text(
              "$count",
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
