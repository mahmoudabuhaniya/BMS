import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../db/hive_manager.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/beneficiary.dart';
import '../models/sync_log.dart';

class SyncService extends ChangeNotifier {
  AuthService? auth;

  bool isOnline = false;
  bool isSyncing = false;

  double progress = 0;
  DateTime? lastSyncTime;
  String? lastError;

  Timer? autoTimer;
  StreamSubscription<List<ConnectivityResult>>? connSub;

  SyncService();

  void attachAuth(AuthService a) {
    auth = a;
  }

  void startAutoSync() {
    _listenConnection();

    autoTimer?.cancel();
    autoTimer = Timer.periodic(
      const Duration(seconds: 40),
      (_) async {
        if (isOnline && !isSyncing) {
          await syncNow();
        }
      },
    );
  }

  int get progressPercent => progress.round();

  void _listenConnection() {
    connSub = Connectivity().onConnectivityChanged.listen((results) async {
      final status =
          results.isNotEmpty ? results.first : ConnectivityResult.none;

      final wasOnline = isOnline;
      isOnline = status != ConnectivityResult.none;
      notifyListeners();

      if (!wasOnline && isOnline) {
        await syncNow();
      }
    });
  }

  Future<void> manualSync() async => syncNow();

  Future<void> syncNow() async {
    if (isSyncing || auth == null) return;

    try {
      isSyncing = true;
      progress = 0;
      notifyListeners();

      final api = ApiService(auth!);

      // ----------------------------------------------------
      // 1. PROCESS LOCAL QUEUE
      // ----------------------------------------------------
      final queue = HiveManager.getQueue();

      int total = queue.length;
      int current = 0;

      for (final item in queue) {
        current++;
        progress = (current / (total == 0 ? 1 : total)) * 40;
        notifyListeners();

        final action = item["action"];
        final payload = item["payload"];
        final b = Beneficiary.fromJson(payload);

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
          final index = HiveManager.getQueue().indexOf(item);
          if (index >= 0) await HiveManager.removeQueueItem(index);
        }
      }

      // ----------------------------------------------------
      // 2. FETCH REMOTE DATA
      // ----------------------------------------------------
      progress = 60;
      notifyListeners();

      final remote = await api.fetchBeneficiaries();

      // ----------------------------------------------------
      // 3. MERGE EXACTLY LIKE OLD WORKING APP
      // ----------------------------------------------------
      final Map<String, Beneficiary> merged = {};

      // --- Add local first
      for (var b in HiveManager.getAll()) {
        merged[b.localId] = b;
      }

      // --- Merge remote (override when same remote.id)
      for (var r in remote) {
        // Check if we already have this Django ID locally
        final match = merged.values.firstWhere(
          (x) => x.id == r.id && r.id != null,
          orElse: () => r,
        );

        // keep SAME localId so UI & Hive keys remain stable
        r.localId = match.localId;

        merged[r.localId] = r;
      }

      // ----------------------------------------------------
      // 4. SAVE MERGED DATA
      // ----------------------------------------------------
      await HiveManager.beneficiaries.clear();

      for (var b in merged.values) {
        await HiveManager.saveBeneficiary(b);
      }
      print("HIVE FINAL COUNT = ${HiveManager.getAll().length}");

      progress = 100;
      lastSyncTime = DateTime.now();

      await HiveManager.addSyncLog(
        SyncLog(
          timestamp: lastSyncTime!,
          message: "Sync OK",
          success: true,
        ),
      );
    } catch (e) {
      lastError = e.toString();
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
  }

  @override
  void dispose() {
    connSub?.cancel();
    autoTimer?.cancel();
    super.dispose();
  }
}
