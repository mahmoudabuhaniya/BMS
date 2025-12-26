import 'package:flutter/material.dart';

class SyncStatusBadge extends StatelessWidget {
  final String status;

  const SyncStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (status) {
      case "yes":
        icon = Icons.cloud_done;
        color = Colors.green;
        break;
      case "update":
        icon = Icons.refresh;
        color = Colors.orange;
        break;
      case "delete":
        icon = Icons.delete;
        color = Colors.grey;
        break;
      default:
        icon = Icons.cloud_off;
        color = Colors.red;
    }

    return Icon(icon, color: color, size: 22);
  }
}
