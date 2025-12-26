import 'package:hive_flutter/hive_flutter.dart';

import '../models/beneficiary.dart';
import '../models/user_profile.dart';
import '../models/sync_log.dart';
import 'package:uuid/uuid.dart';

class HiveManager {
  static const beneficiariesBoxName = "beneficiaries";
  static const pendingQueueBoxName = "pending_queue";
  static const dropdownCacheBoxName = "dropdown_cache";
  static const userProfileBoxName = "user_profile";
  static const syncLogBoxName = "sync_logs";

  static Future<void> initHive() async {
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
    await Hive.openBox(syncLogBoxName);
  }

  // --------------------------------------------------------
  // BOX GETTERS
  // --------------------------------------------------------
  static Box<Beneficiary> get beneficiaries =>
      Hive.box<Beneficiary>(beneficiariesBoxName);

  static Box<Map> get queue => Hive.box<Map>(pendingQueueBoxName);

  static Box get dropdownCache => Hive.box(dropdownCacheBoxName);

  static Box<UserProfile> get userProfile =>
      Hive.box<UserProfile>(userProfileBoxName);

  static Box get syncLogs => Hive.box(syncLogBoxName);

  // --------------------------------------------------------
  // SYNC LOGS
  // --------------------------------------------------------
  static Future<void> addSyncLog(SyncLog log) async =>
      syncLogs.add(log.toJson());

  static List<SyncLog> getSyncLogs() =>
      syncLogs.values.map((e) => SyncLog.fromJson(e)).toList();

  // --------------------------------------------------------
  // BENEFICIARIES
  // --------------------------------------------------------
  static List<Beneficiary> getAll() => beneficiaries.values.toList();

  static Future<void> saveBeneficiary(Beneficiary b) async {
    if (b.id != null) {
      await beneficiaries.put(b.id, b); // remote items
    } else {
      await beneficiaries.put(b.localId, b); // local items (offline)
    }
  }

  // --------------------------------------------------------
  // QUEUE HELPERS
  // --------------------------------------------------------

  static Future<void> pushToQueue(Map data) async {
    await queue.add(data);
  }

  static Future<void> addToQueue(Map data) async {
    await queue.add(data);
  }

  static List<Map> getQueue() => queue.values.toList();

  static Future<void> removeQueueItem(int index) async {
    await queue.deleteAt(index);
  }

  static int get queueCount => queue.length;

  static Future<void> clearQueue() async => queue.clear();

  // --------------------------------------------------------
  // GLOBAL CLEAR (optional)
  // --------------------------------------------------------
  static Future<void> clearAll() async {
    await beneficiaries.clear();
    await queue.clear();
    await dropdownCache.clear();
    await userProfile.clear();
    await syncLogs.clear();
  }
}
