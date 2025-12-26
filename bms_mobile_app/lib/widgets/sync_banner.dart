import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = Provider.of<SyncService>(context);

    Color bg = Colors.green;
    String text = "Synced";

    if (!sync.isOnline) {
      bg = Colors.grey;
      text = "Offline Mode";
    } else if (sync.isSyncing) {
      bg = Colors.orange;
      text = "Syncing…  ${sync.progress.toStringAsFixed(0)}%";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: bg,
      child: Row(
        children: [
          Icon(
            sync.isSyncing ? Icons.sync : Icons.check_circle,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          Text(
            sync.lastSyncTime != null
                ? "Last: ${sync.lastSyncTime!.toLocal().toString().split('.').first}"
                : "Never",
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
