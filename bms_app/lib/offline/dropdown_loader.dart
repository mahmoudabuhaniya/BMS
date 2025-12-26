import 'package:hive/hive.dart';
import '../services/api_service.dart';

class DropdownLoader {
  static final _api = ApiService();

  static Future<Map<String, List<String>>> load() async {
    final box = Hive.box('dropdown_cache');

    // Load cached first
    List<String> ipNames = box.get('ipnames', defaultValue: []).cast<String>();
    List<String> sectors = box.get('sectors', defaultValue: []).cast<String>();

    try {
      final freshIp = await _api.getDistinctIpNames();
      final freshSec = await _api.getDistinctSectors();

      ipNames = freshIp;
      sectors = freshSec;

      box.put('ipnames', ipNames);
      box.put('sectors', sectors);
    } catch (_) {}

    return {
      "ipnames": ipNames,
      "sectors": sectors,
    };
  }
}
