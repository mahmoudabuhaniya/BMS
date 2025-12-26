import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';

class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = Provider.of<SyncService>(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: sync.isSyncing ? Colors.orange.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            sync.isSyncing ? Icons.sync : Icons.check_circle,
            color: sync.isSyncing ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sync.isSyncing
                  ? "Syncing… ${sync.progressPercent}%"
                  : "Everything is up to date",
              style: TextStyle(
                color: sync.isSyncing ? Colors.orange : Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
