import 'package:flutter/material.dart';

class SyncStatusBadge extends StatelessWidget {
  final String? status;
  const SyncStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    String text = "N/A";

    if (status == "yes") {
      color = Colors.green;
      text = "Synced";
    } else if (status == "no") {
      color = Colors.red;
      text = "Local";
    } else if (status == "update") {
      color = Colors.orange;
      text = "Updated";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
}
