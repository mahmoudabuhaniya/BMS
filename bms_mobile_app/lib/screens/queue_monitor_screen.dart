import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/hive_manager.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

class QueueMonitorScreen extends StatefulWidget {
  const QueueMonitorScreen({super.key});

  @override
  State<QueueMonitorScreen> createState() => _QueueMonitorScreenState();
}

class _QueueMonitorScreenState extends State<QueueMonitorScreen> {
  List<Map<String, dynamic>> queue = [];

  @override
  void initState() {
    super.initState();
    _loadQueue();

    // Refresh queue after sync finishes
    final sync = Provider.of<SyncService>(context, listen: false);
    sync.addListener(() {
      if (!sync.isSyncing) _loadQueue();
    });
  }

  void _loadQueue() {
    queue = HiveManager.getQueue();
    if (mounted) setState(() {});
  }

  Future<void> _clearQueue() async {
    await HiveManager.clearQueue();
    _loadQueue();
  }

  Future<void> _removeItem(int index) async {
    await HiveManager.removeQueueItem(index);
    _loadQueue();
  }

  // ----------------------------------------------------------
  // QUEUE CARD
  // ----------------------------------------------------------
  Widget _queueCard(Map<String, dynamic> item, int index) {
    final action = (item["action"] ?? "unknown").toString();
    final payload = Map<String, dynamic>.from(item["payload"] ?? {});

    // Beneficiary fields (null-safe)
    final name = payload["Name"] ?? payload["name"] ?? "Unnamed";
    final idNumber = payload["ID_Number"] ?? payload["id_number"] ?? "-";
    final localId = payload["localId"] ?? "-";
    final ipName = payload["IP_Name"] ?? "-";
    final sector = payload["Sector"] ?? "-";
    final id = payload["id"] ?? null;
    final deleted = payload["Deleted"] == true;
    final restored = (payload["undeleted_at"] != null);

    // Build action label
    String actionLabel = action.toUpperCase();
    if (action == "delete") actionLabel = "DELETE (soft)";
    if (action == "restore") actionLabel = "RESTORE";
    if (action == "update") actionLabel = "UPDATE RECORD";
    if (action == "create") actionLabel = "CREATE NEW";

    // Color for action badge
    Color badgeColor = Colors.grey;
    if (action == "create") badgeColor = Colors.green;
    if (action == "update") badgeColor = Colors.blue;
    if (action == "delete") badgeColor = Colors.red;
    if (action == "restore") badgeColor = Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // TITLE ROW
            // --------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.unicefBlue,
                    ),
                  ),
                ),

                // Action Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // --------------------------------------------------
            // DETAILS
            // --------------------------------------------------
            Text("ID Number: $idNumber"),
            Text("IP Name: $ipName"),
            Text("Sector: $sector"),
            Text("Local ID: $localId"),
            if (id != null) Text("Server ID: $id"),
            if (deleted)
              Text("DELETED: true", style: const TextStyle(color: Colors.red)),
            if (restored)
              Text("RESTORED", style: const TextStyle(color: Colors.orange)),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // REMOVE BUTTON
            // --------------------------------------------------
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeItem(index),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // MAIN BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final sync = Provider.of<SyncService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sync Queue Monitor"),
        backgroundColor: AppTheme.unicefBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadQueue,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // HEADER (queue count + clear all)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  "Queue: ${queue.length}",
                  style: const TextStyle(fontSize: 16),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear All"),
                  onPressed: queue.isEmpty ? null : _clearQueue,
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // LIST
          Expanded(
            child: queue.isEmpty
                ? const Center(
                    child: Text(
                      "No pending operations",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: queue.length,
                    itemBuilder: (_, i) => _queueCard(queue[i], i),
                  ),
          ),
        ],
      ),
    );
  }
}
