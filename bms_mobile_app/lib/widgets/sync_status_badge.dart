import 'package:flutter/material.dart';

class SyncStatusBadge extends StatelessWidget {
  final String? status;

  const SyncStatusBadge({super.key, this.status});

  @override
  Widget build(BuildContext context) {
    final s = status ?? "no";

    Color color = s == "yes"
        ? Colors.green
        : s == "pending"
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        s.toUpperCase(),
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
