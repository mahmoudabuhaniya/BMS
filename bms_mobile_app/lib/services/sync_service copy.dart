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

    try {
      // ----------------------------------------------
      // LOAD LOCAL DATA ONCE (CRITICAL)
      // ----------------------------------------------
      final localList = HiveManager.getAll();
      final localById = <int, Beneficiary>{
        for (final b in localList)
          if (b.id != null) b.id!: b,
      };

      // ----------------------------------------------
      // 1️⃣ PROCESS QUEUE (OFFLINE CHANGES)
      // ----------------------------------------------
      final queue = HiveManager.getQueue();
      int qIndex = 0;

      for (final item in queue) {
        final action = item["action"];
        final b = Beneficiary.fromJson(item["payload"]);

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
        }

        qIndex++;
        progress = (qIndex / (queue.length + 1)) * 20;
      }

      notifyListeners();

      // ----------------------------------------------
      // 2️⃣ FETCH SERVER DATA (PAGE BY PAGE)
      // ----------------------------------------------
      int page = 1;
      const int pageSize = 500;
      int totalCount = 0;
      int fetched = 0;

      while (true) {
        final data = await api.fetchBeneficiariesPage(
          page: page,
          limit: pageSize,
        );

        totalCount = data["count"];
        final results = (data["results"] as List)
            .map((e) => Beneficiary.fromJson(e))
            .toList();

        if (results.isEmpty) break;

        // SAVE PAGE IMMEDIATELY (NO MEMORY BUILDUP)
        for (final remote in results) {
          final local = localById[remote.id];
          if (local != null) {
            remote.localId = local.localId; // preserve identity
          }
          await HiveManager.saveBeneficiary(remote);
        }

        fetched += results.length;

        progress = 20 + (fetched / totalCount) * 60;
        if (progress > 80) progress = 80;
        notifyListeners();

        if (fetched >= totalCount) break;
        page++;
      }

      // ----------------------------------------------
      // 3️⃣ FINALIZE
      // ----------------------------------------------
      progress = 100;
      lastSyncTime = DateTime.now();

      await HiveManager.addSyncLog(
        SyncLog(
          timestamp: lastSyncTime!,
          message: "Sync completed successfully",
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
