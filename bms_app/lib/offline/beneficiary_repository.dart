import 'package:hive/hive.dart';
import '../models/beneficiary.dart';

class BeneficiaryRepository {
  static const boxName = "beneficiaries";

  static Future<Box<Beneficiary>> _box() async =>
      await Hive.openBox<Beneficiary>(boxName);

  static Future<List<Beneficiary>> getAll() async {
    final box = await _box();
    return box.values.toList();
  }

  static Future<List<Beneficiary>> getActive() async {
    final box = await _box();
    return box.values.where((b) => b.deleted == false).toList();
  }

  static Future<List<Beneficiary>> getDeleted() async {
    final box = await _box();
    return box.values.where((b) => b.deleted == true).toList();
  }

  static Future<void> save(Beneficiary b) async {
    final box = await _box();
    await box.put(b.uuid, b);
  }

  static Future<void> updateLocal(Beneficiary b) async {
    final box = await _box();
    await box.put(b.uuid, b);
  }
}
