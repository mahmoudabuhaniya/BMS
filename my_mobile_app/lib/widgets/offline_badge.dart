import 'package:flutter/material.dart';

class OfflineBadge extends StatelessWidget {
  final String synced; // "yes" | "no" | "update" | "delete"

  const OfflineBadge({super.key, required this.synced});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (synced) {
      case 'no':
        icon = Icons.cloud_off;
        color = Colors.redAccent;
        break;
      case 'update':
        icon = Icons.sync;
        color = Colors.orange;
        break;
      case 'delete':
        icon = Icons.delete_forever;
        color = Colors.grey;
        break;
      case 'yes':
      default:
        icon = Icons.cloud_done;
        color = Colors.green;
        break;
    }

    return Icon(icon, color: color, size: 20);
  }
}
