import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final sync = Provider.of<SyncService>(context);

    if (sync.isOnline) {
      return const Icon(Icons.cloud_done, color: Colors.green, size: 22);
    } else {
      return const Icon(Icons.cloud_off, color: Colors.red, size: 22);
    }
  }
}
