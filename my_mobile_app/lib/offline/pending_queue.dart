import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/beneficiary.dart';

/// PENDING QUEUE STRUCTURE:
/// Each entry in Hive "pending_queue" is:
/// {
///   "type": "create" | "update" | "delete",
///   "beneficiary": <beneficiary-json>
/// }
///
/// SyncService reads them in FIFO order.

class PendingQueue {
  static const String boxName = "pending_queue";

  /// Push a NEW beneficiary to queue
  static Future<void> addCreate(Beneficiary b) async {
    final box = await Hive.openBox(boxName);

    final item = {
      "type": "create",
      "beneficiary": b.toJson(), // using toJson from your model
    };

    await box.add(item);
  }

  /// Push UPDATE action
  static Future<void> addUpdate(Beneficiary b) async {
    final box = await Hive.openBox(boxName);

    final item = {
      "type": "update",
      "beneficiary": b.toJson(),
    };

    await box.add(item);
  }

  /// Push DELETE action
  static Future<void> addDelete(Beneficiary b) async {
    final box = await Hive.openBox(boxName);

    final item = {
      "type": "delete",
      "beneficiary": b.toJson(),
    };

    await box.add(item);
  }

  /// Returns all pending items
  static Future<List<Map>> getAll() async {
    final box = await Hive.openBox(boxName);
    return box.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Remove queue item at index (after successful sync)
  static Future<void> removeAt(int index) async {
    final box = await Hive.openBox(boxName);
    if (index < box.length) {
      await box.deleteAt(index);
    }
  }

  /// CLEAR entire queue (not used normally)
  static Future<void> clear() async {
    final box = await Hive.openBox(boxName);
    await box.clear();
  }
}
