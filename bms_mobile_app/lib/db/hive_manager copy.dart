import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/beneficiary.dart';
import '../models/user_profile.dart';
import '../models/sync_log.dart';

class HiveManager {
  // ---------------------------
  // BOX NAMES
  // ---------------------------
  static const beneficiariesBoxName = "beneficiaries";
  static const pendingQueueBoxName = "pendingqueue";
  static const dropdownCacheBoxName = "dropdowncache";
  static const userProfileBoxName = "userprofile";
  static const syncLogBoxName = "synclog";
  static const syncMetaBoxName = "sync_meta";

  // ---------------------------
  // INIT
  // ---------------------------
  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(BeneficiaryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserProfileAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SyncLogAdapter());
    }

    await Hive.openBox(beneficiariesBoxName);
    await Hive.openBox<Map>(pendingQueueBoxName);
    await Hive.openBox(dropdownCacheBoxName);
    await Hive.openBox<UserProfile>(userProfileBoxName);
    await Hive.openBox<SyncLog>(syncLogBoxName);
    await Hive.openBox("tokens");
    await Hive.openBox('meta');
    await Hive.openBox(syncMetaBoxName);
  }

  // ---------------------------
  // BOX GETTERS
  // ---------------------------
  static Box get beneficiaries => Hive.box(beneficiariesBoxName);

  static Box<Map> get queue => Hive.box<Map>(pendingQueueBoxName);

  static Box get dropdownCache => Hive.box(dropdownCacheBoxName);

  static Box<UserProfile> get userProfile =>
      Hive.box<UserProfile>(userProfileBoxName);

  static Box<SyncLog> get syncLog => Hive.box<SyncLog>(syncLogBoxName);

  static Box get syncMeta => Hive.box(syncMetaBoxName);

  static int? getLastSyncedId() {
    return syncMeta.get("last_synced_id");
  }

  static Future<void> setLastSyncedId(int id) async {
    await syncMeta.put("last_synced_id", id);
  }

  // ---------------------------
  // BENEFICIARIES (IMPORTANT)
  // ---------------------------
  /// Always use `localId` as Hive key (stable forever)
  static Future<void> saveBeneficiary(Beneficiary item) async {
    print("Saving to Hive: ${item.id} - ${item.localId}");
    final key = item.localId;
    await beneficiaries.put(key, item);
  }

  static List<Beneficiary> getAll() =>
      beneficiaries.values.cast<Beneficiary>().toList();

  // ---------------------------
  // QUEUE
  // ---------------------------
  static Future<void> pushToQueue(Map<String, dynamic> payload) async {
    await queue.add(payload);
  }

  static List<Map<String, dynamic>> getQueue() {
    return queue.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<void> removeQueueItem(int index) async {
    await queue.deleteAt(index);
  }

  // ---------------------------
  // SYNC LOG
  // ---------------------------
  static Future<void> addSyncLog(SyncLog log) async {
    await syncLog.add(log);
  }

  static List<SyncLog> getSyncLog() {
    return syncLog.values.toList();
  }

  // ---------------------------
  // QUEUE CLEAR
  // ---------------------------
  static Future<void> clearQueue() async {
    await queue.clear();
  }

  String? getLastSync() {
    return Hive.box('meta').get('last_sync');
  }

  void saveLastSync(String serverTime) {
    Hive.box('meta').put('last_sync', serverTime);
  }
}
