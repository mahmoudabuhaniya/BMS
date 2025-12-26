import 'package:hive/hive.dart';
import '../models/beneficiary.dart';

part 'pending_queue.g.dart';

@HiveType(typeId: 2)
class PendingItem {
  @HiveField(0)
  String action; // create / update / delete

  @HiveField(1)
  Beneficiary beneficiary;

  PendingItem({
    required this.action,
    required this.beneficiary,
  });

  Map<String, dynamic> toMap() => {
        "action": action,
        "beneficiary": beneficiary.toJson(),
      };

  static PendingItem fromMap(Map<String, dynamic> map) {
    return PendingItem(
      action: map["action"],
      beneficiary: Beneficiary.fromJson(map["beneficiary"]),
    );
  }
}

class PendingQueue {
  static const String boxName = "pending_queue";

  // Ensure box opened
  static Future<Box> _box() async {
    if (!Hive.isBoxOpen(boxName)) {
      return Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  // ============================================================
  // ADD ACTIONS TO QUEUE
  // ============================================================

  static Future<void> addCreate(Beneficiary b) async {
    final box = await _box();
    await box.add(PendingItem(action: "create", beneficiary: b));
  }

  static Future<void> addUpdate(Beneficiary b) async {
    final box = await _box();
    await box.add(PendingItem(action: "update", beneficiary: b));
  }

  static Future<void> addDelete(Beneficiary b) async {
    final box = await _box();
    await box.add(PendingItem(action: "delete", beneficiary: b));
  }

  // ============================================================
  // FETCH ENTIRE QUEUE
  // ============================================================

  static Future<List<PendingItem>> getAll() async {
    final box = await _box();
    return box.values.cast<PendingItem>().toList();
  }

  // ============================================================
  // REMOVE PROCESSED ITEM
  // ============================================================

  static Future<void> removeAt(int index) async {
    final box = await _box();
    await box.deleteAt(index);
  }

  // Clear everything (rarely used)
  static Future<void> clear() async {
    final box = await _box();
    await box.clear();
  }
}
