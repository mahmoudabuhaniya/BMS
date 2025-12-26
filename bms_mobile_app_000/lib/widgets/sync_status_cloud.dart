import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SyncStatusCloud extends StatelessWidget {
  final String status;

  const SyncStatusCloud({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    IconData icon;

    if (status == "good") {
      icon = FontAwesomeIcons.cloudArrowDown;
    } else if (status == "syncing") {
      icon = FontAwesomeIcons.cloudArrowUp;
    } else {
      icon = FontAwesomeIcons.cloudBolt; // error icon
    }

    return FaIcon(icon, size: 28, color: Colors.blue);
  }
}
