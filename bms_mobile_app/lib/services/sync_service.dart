import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../db/hive_manager.dart';
import '../models/beneficiary.dart';
import '../models/sync_log.dart';
import 'auth_service.dart';
import 'api_service.dart';

class SyncService extends ChangeNotifier {
  AuthService? auth;
  late ApiService api;

  bool isOnline = true;
  bool isSyncing = false;
  double progress = 0;

  Timer? _autoTimer;
  StreamSubscription<List<ConnectivityResult>>? _conn;

  DateTime? lastSyncTime;
  DateTime? get lastSync => lastSyncTime;

  // -------------------------------------------------------------
  // Attach auth AFTER AuthService is ready
  // -------------------------------------------------------------
  void attachAuth(AuthService a) {
    auth = a;
    api = ApiService(a);
  }

  // -------------------------------------------------------------
  // Initialization (NO SYNC HERE)
  // -------------------------------------------------------------
  Future<void> initialize() async {
    _listenConnectivity();

    // Auto sync every 5 minutes (ONLY if logged in)
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => autoSync(),
    );
  }

  // -------------------------------------------------------------
  // Connectivity listener
  // -------------------------------------------------------------
  void _listenConnectivity() {
    _conn = Connectivity().onConnectivityChanged.listen((result) {
      isOnline = result.isNotEmpty && result.first != ConnectivityResult.none;
      notifyListeners();
    });
  }

  // -------------------------------------------------------------
  // Sync triggers
  // -------------------------------------------------------------
  Future<void> autoSync() async {
    if (!isOnline || isSyncing) return;
    await syncNow();
  }

  Future<void> manualSync() async {
    await syncNow();
  }

  // -------------------------------------------------------------
  // 🔥 MAIN SYNC PROCESS (SAFE)
  // -------------------------------------------------------------
  Future<void> syncNow() async {
    if (auth == null || !auth!.isLoggedIn || isSyncing) {
      print("⛔ Sync blocked — user not logged in");
      return;
    }

    isSyncing = true;
    progress = 0;
    notifyListeners();

    try {
      // 🔑 SINGLE source of truth
      final String? lastServerTime = HiveManager.getLastSyncTime();

      // ---------------------------------------------------------
      // 1️⃣ PUSH LOCAL QUEUE
      // ---------------------------------------------------------
      final queue = List<Map>.from(HiveManager.getQueue());

      for (int i = 0; i < queue.length; i++) {
        final item = queue[i];
        final action = item["action"];
        final payload = Map<String, dynamic>.from(item["payload"]);

        Map<String, dynamic>? result;

        if (action == "create") {
          result = await api.createBeneficiary(
            Beneficiary.fromJson(payload),
          );
        } else if (action == "update") {
          result = await api.updateBeneficiary(
            Beneficiary.fromJson(payload),
          );
        } else if (action == "delete") {
          result = await api.deleteBeneficiary(
            id: payload["id"],
            deletedBy: payload["deleted_by"],
          );
        } else if (action == "restore") {
          result = await api.restoreBeneficiary(
            id: payload["id"],
            undeletedBy: payload["undeleted_by"],
          );
        }

        if (result?["success"] == true) {
          if (result?["beneficiary"] != null) {
            await HiveManager.saveBeneficiary(
              Beneficiary.fromJson(result!["beneficiary"]),
            );
          }
          await HiveManager.removeQueueItem(i);
        }
      }

      // ---------------------------------------------------------
      // 2️⃣ PULL FROM SERVER (PAGINATED)
      // ---------------------------------------------------------
      const int pageSize = 1000;
      int page = 1;
      bool hasNext = true;
      String? newServerTime;

      while (hasNext) {
        Map<String, dynamic>? res;

        if (lastServerTime == null) {
          print("🔄 FULL SYNC — page $page");
          print(lastServerTime);
          res = await api.fullSync(page: page, pageSize: pageSize);
        } else {
          print("🔄 INCREMENTAL SYNC — page $page");
          print(lastServerTime);
          res = await api.incrementalSync(
            updatedAfter: lastServerTime,
            page: page,
            pageSize: pageSize,
          );
        }

        if (res == null) {
          throw Exception("Sync failed at page $page");
        }

        final List list = res["results"] ?? [];

        // ✅ SAVE DATA
        for (final item in list) {
          await HiveManager.saveBeneficiary(
            Beneficiary.fromJson(item),
          );
          print(item);
        }

        // ✅ CAPTURE SERVER TIME ON FIRST PAGE
        if (page == 1 && res["server_time"] != null) {
          newServerTime = res["server_time"];
        }

        // ✅ STOP CONDITION (THIS FIXES THE LOOP)
        if (list.length < pageSize) {
          hasNext = false;
        } else {
          page++;
        }

        // Progress (optional)
        final total = res["count"] ?? 0;
        if (total > 0) {
          progress = ((page * pageSize) / total).clamp(0, 1) * 100;
          notifyListeners();
        }
      }

// ✅ SAVE LAST SYNC TIME
      if (newServerTime != null) {
        await HiveManager.saveLastSyncTime(newServerTime);
        lastSyncTime = DateTime.parse(newServerTime);
      }

      progress = 100;
      notifyListeners();

      progress = 100;
      print("✅ Sync completed");
    } catch (e) {
      print("❌ SYNC FAILED: $e");
    }

    isSyncing = false;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Cleanup
  // -------------------------------------------------------------
  @override
  void dispose() {
    _conn?.cancel();
    _autoTimer?.cancel();
    super.dispose();
  }
}
