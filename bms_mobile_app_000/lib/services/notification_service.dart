import 'package:flutter/material.dart';

class NotificationService {
  static void showSuccess(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(SnackBar(backgroundColor: Colors.green, content: Text(msg)));
  }

  static void showError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(
      ctx,
    ).showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(msg)));
  }
}
