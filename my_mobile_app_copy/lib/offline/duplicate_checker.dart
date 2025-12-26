import 'cache/beneficiary_cache.dart';
import '../services/api_service.dart';

class DuplicateChecker {
  static Future<bool> exists(String idNumber) async {
    // 1. check offline cache
    final local = ItemsCache.getLocalItems();
    final localExists =
        local.any((e) => (e['id_number']?.toString() ?? '') == idNumber);
    if (localExists) return true;

    // 2. check online (if possible)
    try {
      final remote = await ApiService.checkDuplicateById(idNumber);
      return remote == true;
    } catch (_) {
      // offline or API error -> assume not found
      return false;
    }
  }
}
