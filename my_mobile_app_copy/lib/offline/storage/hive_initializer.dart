// lib/offline/storage/hive_initializer.dart

import 'package:hive_flutter/hive_flutter.dart';

class HiveInitializer {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Boxes used in new architecture
    await Hive.openBox('cached_items'); // Beneficiaries storage
    await Hive.openBox('pending_submissions'); // Offline queue
  }

  /// Clears all offline data when logging out
  static Future<void> clearAll() async {
    await Hive.box('cached_items').clear();
    await Hive.box('pending_submissions').clear();
  }
}
