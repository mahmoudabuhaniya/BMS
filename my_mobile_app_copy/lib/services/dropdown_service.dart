import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../services/token_service.dart';

class DropdownService {
  static const String ipNamesKey = "dropdown_ip_names";
  static const String sectorsKey = "dropdown_sectors";

  static Future<Map<String, List<String>>> loadDropdowns() async {
    try {
      final token = await TokenService.getToken();
      if (token == null) throw Exception("No token");

      final headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };

      final ipRes = await http.get(
        Uri.parse("${ApiUrls.baseUrl}/distinct/ip-names/"),
        headers: headers,
      );

      final sectorRes = await http.get(
        Uri.parse("${ApiUrls.baseUrl}/distinct/sectors/"),
        headers: headers,
      );

      if (ipRes.statusCode == 200 && sectorRes.statusCode == 200) {
        final ipNames =
            (json.decode(ipRes.body)["ip_names"] as List).cast<String>();
        final sectors =
            (json.decode(sectorRes.body)["sectors"] as List).cast<String>();

        final box = await Hive.openBox("dropdownCache");
        await box.put(ipNamesKey, ipNames);
        await box.put(sectorsKey, sectors);

        return {
          "ip_names": ipNames,
          "sectors": sectors,
        };
      }
    } catch (_) {
      // ignore and fallback to cache
    }

    // offline fallback
    final box = await Hive.openBox("dropdownCache");
    final cachedIp = (box.get(ipNamesKey) ?? []).cast<String>();
    final cachedSec = (box.get(sectorsKey) ?? []).cast<String>();

    return {
      "ip_names": cachedIp,
      "sectors": cachedSec,
    };
  }
}

class ApiUrls {
  static const baseUrl = "https://bms.onastack.com/api"; // ← CHANGE THIS
}
