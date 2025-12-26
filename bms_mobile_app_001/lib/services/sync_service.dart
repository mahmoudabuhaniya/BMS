import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../db/hive_manager.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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
  StreamSubscription? connSub;

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

      // -----------------------------------------------------------
      // 1. PROCESS LOCAL QUEUE
      // -----------------------------------------------------------
      final queue = HiveManager.getQueue();
      final totalQueue = queue.length;
      int qIndex = 0;

      for (final item in queue) {
        qIndex++;
        progress = (qIndex / (totalQueue == 0 ? 1 : totalQueue)) * 30;
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
          await HiveManager.removeQueueItem(
              HiveManager.getQueue().indexOf(item));
        }
      }

      // -----------------------------------------------------------
      // 2. FETCH ALL REMOTE BENEFICIARIES (PAGINATED)
      // -----------------------------------------------------------
      progress = 40;
      notifyListeners();

      final remoteList = await api.fetchAllBeneficiaries();

      // -----------------------------------------------------------
      // 3. MERGE LOCAL UNSYNCED + REMOTE SYNCED
      // -----------------------------------------------------------
      final Map<dynamic, Beneficiary> finalMap = {};

      // First add remote (remote always has real id)
      for (final b in remoteList) {
        if (b.id != null) {
          finalMap[b.id] = b;
        }
      }

      // Then add local non-synced (id == null)
      for (final b in HiveManager.getAll()) {
        if (b.id == null) {
          finalMap[b.localId] = b;
        }
      }

      // -----------------------------------------------------------
      // 4. SAVE MERGED RESULT INTO HIVE
      // -----------------------------------------------------------
      await HiveManager.beneficiaries.clear();

      for (final b in finalMap.values) {
        await HiveManager.saveBeneficiary(b);
      }

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
