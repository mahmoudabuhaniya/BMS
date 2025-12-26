import 'package:hive/hive.dart';
import '../models/beneficiary.dart';

class BeneficiaryRepository {
  static const String boxName = 'beneficiaries';

  /// open Hive box
  static Future<Box> _box() async {
    return await Hive.openBox(boxName);
  }

  /// -----------------------------------------------------
  /// SAVE or UPDATE a beneficiary locally
  /// -----------------------------------------------------
  static Future<void> save(Beneficiary b) async {
    final box = await _box();
    await box.put(b.uuid, b.toMap());
  }

  /// -----------------------------------------------------
  /// Get ALL beneficiaries (including deleted = true)
  /// -----------------------------------------------------
  static Future<List<Beneficiary>> getAll() async {
    final box = await _box();
    return box.values
        .map((e) => Beneficiary.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// -----------------------------------------------------
  /// Get ONLY active beneficiaries
  /// deleted = false
  /// -----------------------------------------------------
  static Future<List<Beneficiary>> getActive() async {
    final box = await _box();
    return box.values
        .map((e) => Beneficiary.fromMap(Map<String, dynamic>.from(e)))
        .where((b) => b.deleted == false)
        .toList();
  }

  /// -----------------------------------------------------
  /// Get deleted beneficiaries (Trash)
  /// -----------------------------------------------------
  static Future<List<Beneficiary>> getDeleted() async {
    final box = await _box();
    return box.values
        .map((e) => Beneficiary.fromMap(Map<String, dynamic>.from(e)))
        .where((b) => b.deleted == true)
        .toList();
  }

  /// -----------------------------------------------------
  /// Mark record as locally deleted
  /// synced will become "delete"
  /// -----------------------------------------------------
  static Future<void> markDeleted(String uuid) async {
    final box = await _box();
    if (!box.containsKey(uuid)) return;

    final data = Map<String, dynamic>.from(box.get(uuid));

    data['deleted'] = true;
    data['synced'] = 'delete';

    await box.put(uuid, data);
  }

  /// -----------------------------------------------------
  /// Replace entire list after sync from server
  /// (used on first login or manual refresh)
  /// -----------------------------------------------------
  static Future<void> overwriteAll(List<Beneficiary> beneficiaries) async {
    final box = await _box();
    await box.clear();

    for (var b in beneficiaries) {
      await box.put(b.uuid, b.toMap());
    }
  }

  /// -----------------------------------------------------
  /// Find a record by UUID
  /// -----------------------------------------------------
  static Future<Beneficiary?> findByUUID(String uuid) async {
    final box = await _box();
    if (!box.containsKey(uuid)) return null;

    return Beneficiary.fromMap(Map<String, dynamic>.from(box.get(uuid)));
  }
}
