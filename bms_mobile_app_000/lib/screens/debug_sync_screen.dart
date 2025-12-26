import 'package:flutter/material.dart';
import '../db/hive_manager.dart';
import '../theme/app_theme.dart';

class DebugSyncScreen extends StatefulWidget {
  const DebugSyncScreen({super.key});

  @override
  State<DebugSyncScreen> createState() => _DebugSyncScreenState();
}

class _DebugSyncScreenState extends State<DebugSyncScreen> {
  List<Map> queue = [];

  @override
  void initState() {
    super.initState();
    loadQueue();
  }

  void loadQueue() {
    queue = HiveManager.pendingQueue.values.toList().cast<Map>();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sync Queue Monitor"),
        backgroundColor: AppTheme.unicefBlue,
      ),
      body: queue.isEmpty
          ? const Center(child: Text("Queue is empty"))
          : ListView.builder(
              itemCount: queue.length,
              itemBuilder: (_, i) {
                final item = queue[i];

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(item["type"] ?? "Unknown"),
                    subtitle: Text(item.toString()),
                  ),
                );
              },
            ),
    );
  }
}
