import '../services/api_service.dart';

class DropdownLoader {
  static final ApiService _api = ApiService();

  static Future<Map<String, List<String>>> loadDistinctValues() async {
    try {
      final ipNames = await _api.fetchDistinctIpNames();
      final sectors = await _api.fetchDistinctSectors();

      ipNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      sectors.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      return {
        'ip_names': ipNames,
        'sectors': sectors,
      };
    } catch (e) {
      return {
        'ip_names': <String>[],
        'sectors': <String>[],
      };
    }
  }
}
