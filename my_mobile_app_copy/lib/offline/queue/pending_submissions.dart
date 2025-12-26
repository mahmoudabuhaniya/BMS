import 'package:hive_flutter/hive_flutter.dart';

class PendingSubmissions {
  static const _boxName = 'pending_submissions';

  static Box get _box => Hive.box(_boxName);

  static Future<void> addCreate(Map<String, dynamic> data) async {
    await _box.add({'type': 'create', 'payload': data});
  }

  static Future<void> addUpdate(int id, Map<String, dynamic> data) async {
    await _box.add({'type': 'update', 'id': id, 'payload': data});
  }

  static Future<List<Map<String, dynamic>>> getAll() async {
    return _box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Future<void> removeAt(int index) async {
    final key = _box.keyAt(index);
    await _box.delete(key);
  }
}
