import 'package:hive_flutter/hive_flutter.dart';
import '../models/beneficiary.dart';

class HiveManager {
  static late Box<Beneficiary> beneficiariesBox;
  static late Box<Map> pendingQueue;
  static late Box authBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(BeneficiaryAdapter());
    }

    beneficiariesBox = await Hive.openBox<Beneficiary>('beneficiaries');
    pendingQueue = await Hive.openBox<Map>('pendingQueue');
    authBox = await Hive.openBox('auth');
  }

  /// Save or update a beneficiary
  static Future<void> saveBeneficiary(Beneficiary item) async {
    if (item.id == null) return;

    await beneficiariesBox.put(item.id, item);
  }

  /// Return all items (including deleted)
  static List<Beneficiary> getAll() {
    return beneficiariesBox.values.toList();
  }

  static Future<void> queueSave(String action, Map payload) async {
    await pendingQueue.add({
      "action": action,
      "payload": payload,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }

  static int get queueCount => pendingQueue.length;

  static List<Map> getQueue() => pendingQueue.values.toList();

  static Future<void> clearQueue() async => pendingQueue.clear();

  static Future<void> removeQueueItem(int index) async {
    await pendingQueue.deleteAt(index);
  }

  /// FIXED: id is int, not string
  static Future<void> deleteById(int id) async {
    await beneficiariesBox.delete(id);
  }
}
