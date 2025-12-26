import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/beneficiary.dart';
import '../offline/pending_queue.dart';
import '../offline/beneficiary_repository.dart';
import '../services/api_service.dart';

class SyncService {
  static bool _syncing = false;
  static Timer? _timer;

  /// Start periodic sync every 30 seconds
  static void startAutoSync() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      processQueue();
    });
  }

  /// Runs on app launch (main.dart)
  static Future<void> initialSync() async {
    await processQueue();
  }

  /// Core sync logic
  static Future<void> processQueue() async {
    if (_syncing) return; // prevent duplicate concurrency
    _syncing = true;

    try {
      // Check internet
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        _syncing = false;
        return;
      }

      final queue = await PendingQueue.getAll();
      if (queue.isEmpty) {
        _syncing = false;
        return;
      }

      final api = ApiService();

      // Process one item at a time
      for (int i = 0; i < queue.length; i++) {
        final item = queue[i];
        if (item == null) continue;

        final String action = item["action"];
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(item["data"] ?? {});
        final String uuid = item["uuid"];

        Beneficiary b = Beneficiary.fromMap({
          ...data,
          "uuid": uuid,
        });

        try {
          if (action == "create") {
            final serverRecord = await api.pushCreate(b);
            b.applyServerSync(serverRecord);
            b.synced = "yes";
            await BeneficiaryRepository.updateLocal(b);
          } else if (action == "update") {
            final serverRecord = await api.pushUpdate(b);
            b.applyServerSync(serverRecord);
            b.synced = "yes";
            await BeneficiaryRepository.updateLocal(b);
          } else if (action == "delete") {
            await api.pushDelete(b);
            b.deleted = true;
            b.synced = "yes";
            await BeneficiaryRepository.updateLocal(b);
          }

          // Remove item from queue
          await PendingQueue.removeAt(i);
        } catch (e) {
          // Stop processing further items
          break;
        }
      }
    } finally {
      _syncing = false;
    }
  }
}
