import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../db/hive_manager.dart';
import '../models/beneficiary.dart';
import 'api_service.dart';
import 'auth_service.dart';

class SyncService extends ChangeNotifier {
  bool isSyncing = false;
  bool isOnline = false;

  Timer? _timer;
  late ApiService api;
  late AuthService auth;

  SyncService();

  // Must be called after providers initialized
  void init(AuthService authService) {
    auth = authService;
    api = ApiService(auth);

    _startListeners();
    _startBackgroundTimer();
  }

  // ------------------------------------------------------------
  // CONNECTIVITY LISTENER
  // ------------------------------------------------------------
  void _startListeners() {
    Connectivity().onConnectivityChanged.listen((status) {
      isOnline = status != ConnectivityResult.none;
      notifyListeners();

      if (isOnline) {
        syncNow();
      }
    });
  }

  // ------------------------------------------------------------
  // BACKGROUND TIMER (EVERY 30 SECONDS)
  // ------------------------------------------------------------
  void _startBackgroundTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (isOnline && !isSyncing) {
        syncNow();
      }
    });
  }

  // ------------------------------------------------------------
  // MAIN SYNC FUNCTION
  // ------------------------------------------------------------
  Future<void> syncNow() async {
    if (!isOnline) return;

    if (isSyncing) return;

    isSyncing = true;
    notifyListeners();

    try {
      await _processQueue();
      await _refreshRemoteData();
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------
  // PROCESS QUEUE (CREATE / UPDATE / DELETE)
  // ------------------------------------------------------------
  Future<void> _processQueue() async {
    while (true) {
      final item = await HiveManager.popQueue();
      if (item == null) break;

      String action = item["action"];
      String uuid = item["uuid"];
      Map payload = item["payload"];

      Beneficiary? local;

      for (var b in HiveManager.beneficiaries.values) {
        if (b.uuid == uuid) {
          local = b;
          break;
        }
      }

      if (local == null) {
        return; // nothing to sync
      }

      if (action == "create") {
        await _syncCreate(local);
      } else if (action == "update") {
        await _syncUpdate(local);
      } else if (action == "delete") {
        await _syncDelete(local);
      }
    }
  }

  // ------------------------------------------------------------
  // CREATE SYNC
  // ------------------------------------------------------------
  Future<void> _syncCreate(Beneficiary b) async {
    final id = await api.createBeneficiary(b);
    if (id == null) {
      // failed → push again later
      await HiveManager.pushToQueue({
        "action": "create",
        "uuid": b.uuid,
        "payload": b.toJson(),
      });
      return;
    }

    // success → update database
    b.id = id;
    b.synced = "yes";
    await b.save();
  }

  // ------------------------------------------------------------
  // UPDATE SYNC
  // ------------------------------------------------------------
  Future<void> _syncUpdate(Beneficiary b) async {
    if (b.id == null) {
      // No remote ID → treat as create
      await _syncCreate(b);
      return;
    }

    final ok = await api.updateBeneficiary(b);
    if (!ok) {
      // retry later
      await HiveManager.pushToQueue({
        "action": "update",
        "uuid": b.uuid,
        "payload": b.toJson(),
      });
      return;
    }

    b.synced = "yes";
    await b.save();
  }

  // ------------------------------------------------------------
  // DELETE SYNC
  // ------------------------------------------------------------
  Future<void> _syncDelete(Beneficiary b) async {
    if (b.id == null) {
      // if record has never synced, fully delete local
      await b.delete();
      return;
    }

    final ok = await api.deleteBeneficiary(b.id!);
    if (!ok) {
      // retry later
      await HiveManager.pushToQueue({
        "action": "delete",
        "uuid": b.uuid,
        "payload": {},
      });
      return;
    }

    // Mark synced deleted
    b.synced = "yes";
    await b.save();
  }

  // ------------------------------------------------------------
  // REFRESH REMOTE DATA → LOCAL HIVE
  // ------------------------------------------------------------
  Future<void> _refreshRemoteData() async {
    final remote = await api.fetchBeneficiaries();
    if (remote.isEmpty) return;

    final box = HiveManager.beneficiaries;

    // Keep offline-created or pending items
    final pending = box.values.where((b) => b.synced != "yes").toList();

    await box.clear();

    // Load fresh server data
    for (final b in remote) {
      await box.add(b);
    }

    // Re-add pending local modifications
    for (final p in pending) {
      await box.add(p);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
