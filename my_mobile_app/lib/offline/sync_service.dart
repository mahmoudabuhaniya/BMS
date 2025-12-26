import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/beneficiary.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../offline/pending_queue.dart';
import '../offline/beneficiary_repository.dart';

/// OFFLINE-FIRST SYNC ENGINE
/// -------------------------
/// Queue entries:
///  - type: create | update | delete
///  - beneficiary: <json>
///
/// Sync flow:
/// 1. Check internet
/// 2. Pop the FIRST queue item
/// 3. Execute correct API call
/// 4. Update local beneficiary copy
/// 5. Remove item from queue
/// 6. Loop until empty
///
/// This engine runs on:
/// ✔ App start
/// ✔ App resume
/// ✔ Manual Sync
/// ✔ Timer (every 30–60 sec)
class SyncService {
  final ApiService _api = ApiService();

  /// PUBLIC — call this from main.dart or home screen
  static Future<void> processQueue() async {
    final service = SyncService();
    await service._processQueueInternal();
  }

  /// INTERNAL — safe sequential processor
  Future<void> _processQueueInternal() async {
    final online = await _isOnline();
    if (!online) {
      log("⛔ Offline — skipping sync.");
      return;
    }

    log("🔄 SyncService: Checking queue...");

    final queue = await PendingQueue.getAll();
    if (queue.isEmpty) {
      log("✅ Queue empty — nothing to sync.");
      return;
    }

    log("📦 Pending items: ${queue.length}");

    // FIFO processing
    for (int i = 0; i < queue.length; i++) {
      final item = queue[i];
      final type = item["type"];
      final data = item["beneficiary"];

      final Beneficiary b = Beneficiary.fromJson(data);

      try {
        if (type == "create") {
          await _syncCreate(b);
        } else if (type == "update") {
          await _syncUpdate(b);
        } else if (type == "delete") {
          await _syncDelete(b);
        }

        // Important: Remove FIRST element every time
        await PendingQueue.removeAt(0);
      } catch (e, stack) {
        log("❌ Error syncing item ($type): $e");
        log(stack.toString());
        break; // Stop processing to avoid data corruption
      }
    }

    log("🎉 SyncService: Sync complete!");
  }

  // ---------------------------------------------------------------------------
  // CREATE
  // ---------------------------------------------------------------------------
  Future<void> _syncCreate(Beneficiary b) async {
    log("🟦 Sync CREATE for ${b.idNumber}");

    final response = await _api.createBeneficiary(b.toJson());

    // backend returns the new ID
    final updated = b.copyWith(
      id: response.id,
      synced: "yes",
    );

    await BeneficiaryRepository.save(updated);
  }

  // ---------------------------------------------------------------------------
  // UPDATE
  // ---------------------------------------------------------------------------
  Future<void> _syncUpdate(Beneficiary b) async {
    if (b.id == null) {
      log("⚠ Cannot UPDATE — beneficiary has no backend ID.");
      return;
    }

    log("🟧 Sync UPDATE for ID ${b.id}");

    await _api.updateBeneficiary(b.id!, b.toJson());

    final updated = b.copyWith(synced: "yes");
    await BeneficiaryRepository.save(updated);
  }

  // ---------------------------------------------------------------------------
  // DELETE
  // ---------------------------------------------------------------------------
  Future<void> _syncDelete(Beneficiary b) async {
    if (b.id == null) {
      log("⚠ Cannot DELETE — beneficiary has no backend ID.");
      return;
    }

    log("⬛ Sync DELETE for ID ${b.id}");

    await _api.deleteBeneficiary(b.id!);

    // Remove from local DB too
    await BeneficiaryRepository.delete(b.uuid);
  }

  // ---------------------------------------------------------------------------
  // CHECK NETWORK CONNECTIVITY
  // ---------------------------------------------------------------------------
  Future<bool> _isOnline() async {
    final conn = await Connectivity().checkConnectivity();
    return conn != ConnectivityResult.none;
  }
}
