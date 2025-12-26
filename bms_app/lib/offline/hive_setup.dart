import 'package:hive_flutter/hive_flutter.dart';
import '../models/beneficiary.dart';

class HiveSetup {
  static const String beneficiariesBox = "beneficiaries_box";
  static const String queueBox = "pending_queue_box";
  static const String dropdownBox = "dropdown_cache_box";

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters safely
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(BeneficiaryAdapter());
    }

    // Open boxes
    await Hive.openBox(beneficiariesBox);
    await Hive.openBox(queueBox);
    await Hive.openBox(dropdownBox);
  }

  static Box get beneficiaries => Hive.box(beneficiariesBox);

  static Box get queue => Hive.box(queueBox);

  static Box get dropdown => Hive.box(dropdownBox);
}
