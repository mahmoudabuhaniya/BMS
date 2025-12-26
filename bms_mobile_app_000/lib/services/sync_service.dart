import 'dart:async';
import 'package:flutter/material.dart';
import '../models/beneficiary.dart';
import '../db/hive_manager.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'network_service.dart';

class SyncService extends ChangeNotifier {
  AuthService? auth; // ⭐ must NOT be final
  late ApiService api; // ⭐ must be recreated when auth updates

  bool isOnline = false;
  bool isSyncing = false;
  double progress = 0;
  DateTime? lastSuccess;
  String? lastErrorMessage;

  Timer? _timer;

  SyncService(this.auth) {
    api = ApiService(auth);
  }

  // ⭐ FIX: This gets called when AuthService changes (after login)
  void updateAuth(AuthService newAuth) {
    auth = newAuth;
    api.updateAuth(newAuth);
    notifyListeners();
  }

  // START SYNC LISTENER
  Future<void> start() async {
    await _checkConnection();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 40), (_) => syncNow());
  }

  Future<void> _checkConnection() async {
    isOnline = await NetworkService.hasInternet();
    notifyListeners();
  }

  Future<void> manualSync() async => await syncNow();
  Future<void> triggerAutoSync() async => await syncNow();

  // MAIN SYNC
  Future<void> syncNow() async {
    if (isSyncing) return;

    await _checkConnection();
    if (!isOnline) return;

    if (auth?.accessToken == null || auth!.accessToken!.isEmpty) {
      print("❌ NO ACCESS TOKEN — SYNC SKIPPED");
      return;
    }

    print("🔵 STARTING SYNC... TOKEN OK");

    isSyncing = true;
    lastErrorMessage = null;
    progress = 0;
    notifyListeners();

    // PROCESS QUEUE
    final queue = HiveManager.pendingQueue.values.toList();

    int index = 0;
    for (final item in queue) {
      try {
        final action = item["action"];
        final payload = item["payload"];
        final b = Beneficiary.fromJson(payload);

        if (action == "create_or_update") {
          if (b.id == null) {
            final res = await api.createBeneficiary(b);
            if (res.success) {
              b.id = res.data["id"];
              b.synced = "yes";
              await HiveManager.saveBeneficiary(b);
            }
          } else {
            final res = await api.updateBeneficiary(b);
            if (res.success) {
              b.synced = "yes";
              await HiveManager.saveBeneficiary(b);
            }
          }
        }

        await HiveManager.pendingQueue.deleteAt(index);
      } catch (e) {
        lastErrorMessage = e.toString();
      }

      index++;
      progress = index / queue.length;
      notifyListeners();
    }

    // REFRESH FROM API
    try {
      print("🔵 Fetching full dataset from server…");
      final remote = await api.fetchAllPaginated();

      print("🔵 Fetched: ${remote.length} records");

      // ---------------------------------------
      // SAVE REMOTE LIST INTO HIVE CORRECTLY
      // ---------------------------------------
      final box = HiveManager.beneficiariesBox;
      await box.clear();

      for (final b in remote) {
        dynamic key;

        // Prefer server ID if exists
        if (b.id != null) {
          key = b.id;
        }
        // If offline local record had uuid, keep consistent
        else if (b.uuid != null && b.uuid!.isNotEmpty) {
          key = b.uuid;
        }

        if (key != null) {
          await box.put(key, b);
        } else {
          // last fallback
          await box.add(b);
        }
      }

      print("✅ Hive saved ${box.length} beneficiaries");
      lastSuccess = DateTime.now();

      print("✅ Hive saved ${box.length} beneficiaries");
      lastSuccess = DateTime.now();
    } catch (e) {
      lastErrorMessage = e.toString();
      print("❌ Sync error: $e");
    }

    isSyncing = false;
    notifyListeners();
  }
}
