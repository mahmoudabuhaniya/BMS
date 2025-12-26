import 'package:hive_flutter/hive_flutter.dart';
import '../../models/beneficiary.dart';

class BeneficiaryCache {
  static const _boxName = 'beneficiaries';

  static Box get _box => Hive.box(_boxName);

  static Future<List<Beneficiary>> getAll() async {
    final values = _box.values;
    return values
        .whereType<Map>()
        .map((m) => Beneficiary.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  static Future<void> saveAll(List<Beneficiary> items) async {
    await _box.clear();
    for (final b in items) {
      await _box.add(b.toJson());
    }
  }
}
