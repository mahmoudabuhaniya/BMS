import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/beneficiary.dart';
import '../models/user_profile.dart';
import '../models/sync_log.dart';

class HiveManager {
  // ------------------------------
  // BOX NAMES
  // ------------------------------
  static const beneficiariesBoxName = "beneficiaries";
  static const pendingQueueBoxName = "pendingqueue";
  static const dropdownCacheBoxName = "dropdowncache";
  static const userProfileBoxName = "userprofile";
  static const syncLogBoxName = "synclog";
  static const syncMetaBoxName = "sync_meta";

  // ------------------------------
  // INIT
  // ------------------------------
  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(BeneficiaryAdapter());
    if (!Hive.isAdapterRegistered(2))
      Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(SyncLogAdapter());

    await Hive.openBox<Beneficiary>(beneficiariesBoxName);
    await Hive.openBox<Map>(pendingQueueBoxName);
    await Hive.openBox(dropdownCacheBoxName);
    await Hive.openBox<UserProfile>(userProfileBoxName);
    await Hive.openBox<SyncLog>(syncLogBoxName);
    await Hive.openBox(syncMetaBoxName);
    await Hive.openBox("tokens");
  }

  // ------------------------------
  // BOX GETTERS
  // ------------------------------
  static Box<Beneficiary> get beneficiaries =>
      Hive.box<Beneficiary>(beneficiariesBoxName);

  static Box<Map> get queue => Hive.box<Map>(pendingQueueBoxName);

  static Box get dropdownCache => Hive.box(dropdownCacheBoxName);

  static Box<UserProfile> get userProfile =>
      Hive.box<UserProfile>(userProfileBoxName);

  static Box<SyncLog> get syncLog => Hive.box<SyncLog>(syncLogBoxName);

  static Box get syncMeta => Hive.box(syncMetaBoxName);

  // ------------------------------
  // LAST SYNC TIME
  // ------------------------------
  static const String _lastSyncKey = "last_sync_time";

  static Future<void> saveLastSyncTime(String serverTime) async {
    final box = Hive.box('meta');
    await box.put(_lastSyncKey, serverTime);
  }

  static String? getLastSyncTime() {
    final box = Hive.box('meta');
    return box.get(_lastSyncKey);
  }

  // =============================================================
  // 🔥 BENEFICIARY SAVE LOGIC (Critical for Sync Engine)
  // =============================================================
  static Future<void> saveBeneficiary(Beneficiary b) async {
    final box = beneficiaries;

    // 1️⃣ Try match existing record by server ID
    if (b.id != null) {
      final existingKey = box.keys.cast<int?>().firstWhere(
            (k) => box.get(k)?.id == b.id,
            orElse: () => null,
          );

      if (existingKey != null) {
        b.localId = existingKey;
        await box.put(existingKey, b);
        return;
      }
    }

    // 2️⃣ New record → let Hive assign key
    final newKey = await box.add(b);
    b.localId = newKey;
  }

  // --------------------------------------------------------------
  // GET ALL BENEFICIARIES
  // --------------------------------------------------------------
  static List<Beneficiary> getAll() {
    return beneficiaries.values.toList();
  }

  // =============================================================
  // 🔥 QUEUE OPERATIONS (for offline actions)
  // =============================================================
  static Future<void> pushToQueue(Map<String, dynamic> item) async {
    await queue.add(item);
  }

  static List<Map<String, dynamic>> getQueue() {
    return queue.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Safe removal (prevents index mix-up after deletes)
  static Future<void> removeQueueItem(int index) async {
    if (index < queue.length) {
      await queue.deleteAt(index);
    }
  }

  static Future<void> clearQueue() async {
    await queue.clear();
  }

  // =============================================================
  // 🔥 SYNC LOGS
  // =============================================================
  static Future<void> addSyncLog(SyncLog log) async {
    await syncLog.add(log);
  }

  static List<SyncLog> getSyncLog() {
    return syncLog.values.toList();
  }
}
