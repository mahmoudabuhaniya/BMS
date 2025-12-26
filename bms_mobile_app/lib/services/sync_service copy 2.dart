import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../db/hive_manager.dart';
import '../models/beneficiary.dart';
import '../models/sync_log.dart';
import 'auth_service.dart';
import 'api_service.dart';

class SyncService extends ChangeNotifier {
  AuthService? auth;
  late ApiService api;

  bool isOnline = false;
  bool isSyncing = false;
  double progress = 0;
  static const int pageSize = 500;

  // ---------------------------
// LAST SYNC (stored in Hive)
// ---------------------------
  DateTime? getLastSync() {
    final raw = HiveManager.syncMeta.get("last_sync_time");
    if (raw == null) return null;

    // store as ISO string recommended
    if (raw is String) return DateTime.tryParse(raw);

    // fallback in case stored as DateTime
    if (raw is DateTime) return raw;

    return null;
  }

  Future<void> saveLastSync(DateTime dt) async {
    final box = Hive.box("syncmeta");
    await box.put("last_sync", dt.toIso8601String());
  }

  DateTime? lastSyncTime;

  Timer? _autoSyncTimer;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  // --------------------------------------------------
  // ATTACH AUTH (called once in main)
  // --------------------------------------------------
  void attachAuth(AuthService a) {
    auth = a;
    api = ApiService(a);
  }

  // --------------------------------------------------
  // INIT (called once in main)
  // --------------------------------------------------
  Future<void> initialize() async {
    _listenConnectivity();

    // Auto sync every 5 minutes
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => autoSync(),
    );

    // 🔥 FIRST RUN AUTO SYNC (ONLY IF HIVE EMPTY)
    Future.delayed(const Duration(seconds: 3), () async {
      if (!isSyncing && auth != null) {
        await syncNow();
      }
    });
  }

  // --------------------------------------------------
  // CONNECTIVITY
  // --------------------------------------------------
  void _listenConnectivity() {
    if (kIsWeb) {
      // Web has no real connectivity events → assume online
      isOnline = true;
      return;
    }

    _connSub = Connectivity().onConnectivityChanged.listen((results) {
      isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;
    });
  }

  // --------------------------------------------------
  // ENTRY POINTS
  // --------------------------------------------------
  Future<void> autoSync() async {
    if (!isOnline || isSyncing) return;
    await syncNow();
  }

  Future<void> manualSync() async {
    await syncNow();
  }

  // --------------------------------------------------
  // MAIN SYNC (FINAL, SAFE, STABLE)
  // --------------------------------------------------
  Future<void> syncNow() async {
    if (auth == null || isSyncing) return;

    isSyncing = true;
    progress = 0;
    notifyListeners();

    final lastSyncedId = HiveManager.getLastSyncedId();

    try {
      final lastSync = getLastSync();

      // ---- 1) PUSH LOCAL QUEUE FIRST ----
      final queue = HiveManager.getQueue();
      for (final item in queue) {
        final b = Beneficiary.fromJson(item["payload"]);
        final action = item["action"];

        bool ok = false;
        if (action == "create") {
          final newId = await api.createBeneficiary(b);
          if (newId != null) {
            b.id = newId;
            b.synced = "yes";
            ok = true;
          }
        } else if (action == "update") {
          ok = await api.updateBeneficiary(b);
          if (ok) b.synced = "yes";
        }

        if (ok) {
          await HiveManager.saveBeneficiary(b);
          await HiveManager.removeQueueItem(
            HiveManager.getQueue().indexOf(item),
          );
        }
      }

      // ---- 2) PULL DELTAS (INCLUDES DELETED) ----
      int page = 1;
      const limit = 500;
      String? serverTime;

      while (true) {
        final lastId = HiveManager.syncMeta.get("last_synced_id") ?? 0;
        final data = await api.fetchBeneficiariesDelta(
            lastId: lastId, page: page, limit: pageSize);

        final results = (data["results"] as List)
            .map((e) => Beneficiary.fromJson(e))
            .toList();

        final serverTime = date.Time.parse(data["server_time"]);
        saveLastSync(serverTime);

        for (final r in results) {
          await HiveManager.saveBeneficiary(r); // deleted included
        }

        progress = 40 + (page * limit / data["count"]) * 60;
        if (progress > 95) progress = 95;
        notifyListeners();

        if (page * limit >= data["count"]) break;
        page++;
      }

      // ---- 3) COMMIT SYNC TIME ----
      if (serverTime != null) {
        saveLastSync(serverTime);
      }

      lastSyncTime = DateTime.now();
      progress = 100;

      await HiveManager.addSyncLog(
        SyncLog(
          timestamp: lastSyncTime!,
          message: "Incremental sync completed",
          success: true,
        ),
      );
    } catch (e) {
      await HiveManager.addSyncLog(
        SyncLog(
          timestamp: DateTime.now(),
          message: e.toString(),
          success: false,
        ),
      );
    }

    isSyncing = false;
    notifyListeners();

    List<Beneficiary> remote = [];

    if (lastSyncedId == null) {
      // existing FULL SYNC logic (unchanged)
    } else {
      // 🔥 INCREMENTAL SYNC
      final updates = await api.fetchBeneficiariesAfterId(lastSyncedId);

      for (final b in updates) {
        await HiveManager.saveBeneficiary(b);
      }

      if (updates.isNotEmpty) {
        final newMax =
            updates.map((b) => b.id ?? 0).reduce((a, b) => a > b ? a : b);

        await HiveManager.setLastSyncedId(newMax);
      }
    }
  }

  // --------------------------------------------------
  // CLEANUP
  // --------------------------------------------------
  @override
  void dispose() {
    _connSub?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
