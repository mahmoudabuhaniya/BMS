import 'package:hive_flutter/hive_flutter.dart';

class HiveInitializer {
  static Future<void> init() async {
    await Hive.initFlutter();

    await Hive.openBox('beneficiaries'); // cached server list
    await Hive.openBox('pending_queue'); // offline unsynced creates
    await Hive.openBox('dropdown_cache'); // ip_names + sectors
  }
}
