import '../../models/beneficiary.dart';
import 'beneficiary_cache.dart';

class ItemsCache {
  static Future<void> saveOrUpdateLocal(Map<String, dynamic> data) async {
    final b = Beneficiary.fromMap(Map<String, dynamic>.from(data));
    await BeneficiaryCache.saveLocal(b);
  }
}
