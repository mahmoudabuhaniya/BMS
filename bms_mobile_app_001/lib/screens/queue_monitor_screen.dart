import 'package:flutter/material.dart';
import '../db/hive_manager.dart';

class QueueMonitorScreen extends StatefulWidget {
  const QueueMonitorScreen({super.key});

  @override
  State<QueueMonitorScreen> createState() => _QueueMonitorScreenState();
}

class _QueueMonitorScreenState extends State<QueueMonitorScreen> {
  @override
  Widget build(BuildContext context) {
    final queue = HiveManager.getQueue();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sync Queue Monitor"),
      ),
      body: queue.isEmpty
          ? const Center(
              child: Text("Queue is empty",
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
            )
          : ListView.builder(
              itemCount: queue.length,
              itemBuilder: (_, i) {
                final item = queue[i];
                return ListTile(
                  title: Text("${item["action"]} — ${item["uuid"]}"),
                  subtitle: Text(item["payload"].toString()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await HiveManager.removeQueueItem(i);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }
}
