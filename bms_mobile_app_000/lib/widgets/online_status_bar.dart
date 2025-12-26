import 'package:flutter/material.dart';

class OnlineStatusBar extends StatelessWidget {
  final bool isOnline;

  const OnlineStatusBar({super.key, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: isOnline ? Colors.green : Colors.red,
      child: Text(
        isOnline ? "Online" : "Offline Mode",
        style: const TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
    );
  }
}
