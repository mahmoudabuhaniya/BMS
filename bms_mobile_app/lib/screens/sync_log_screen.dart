import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/hive_manager.dart';
import '../models/sync_log.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

class SyncLogScreen extends StatefulWidget {
  const SyncLogScreen({super.key});

  @override
  State<SyncLogScreen> createState() => _SyncLogScreenState();
}

class _SyncLogScreenState extends State<SyncLogScreen> {
  List<SyncLog> logs = [];

  @override
  void initState() {
    super.initState();

    _loadLogs();

    // When sync completes → refresh logs
    final sync = Provider.of<SyncService>(context, listen: false);
    sync.addListener(() {
      if (!sync.isSyncing) _loadLogs();
    });
  }

  // Load & sort logs (newest first)
  void _loadLogs() {
    logs = HiveManager.getSyncLog()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (mounted) setState(() {});
  }

  // Clear all logs
  Future<void> _clearLogs() async {
    await HiveManager.syncLog.clear();
    _loadLogs();
  }

  // ----------------------------------------------
  // SINGLE LOG CARD
  // ----------------------------------------------
  Widget _logCard(SyncLog log) {
    final bool success = log.success;
    final icon = success ? Icons.check_circle : Icons.error;
    final color = success ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.timestamp.toLocal().toString().split('.').first,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.unicefBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  log.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: success ? Colors.black87 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------
  // MAIN BUILD
  // ----------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sync Logs"),
        backgroundColor: AppTheme.unicefBlue,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: logs.isEmpty ? null : _clearLogs,
          ),
        ],
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadLogs(),
        child: logs.isEmpty
            ? const Center(
                child: Text(
                  "No sync logs available",
                  style: TextStyle(fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: logs.length,
                itemBuilder: (_, i) => _logCard(logs[i]),
              ),
      ),
    );
  }
}
