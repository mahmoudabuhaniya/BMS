import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';

class ApiService {
  static const baseUrl = 'https://bms.onastack.com/api';

  static Future<Map<String, dynamic>> get(String path) async {
    final token = await TokenService.getToken();
    final response = await http.get(
      Uri.parse('\$baseUrl\$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer \$token',
      },
    );
    return _processResponse(response);
  }

  static Future<Map<String, dynamic>> post(String path, Map body) async {
    final token = await TokenService.getToken();
    final response = await http.post(
      Uri.parse('\$baseUrl\$path'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer \$token',
      },
      body: jsonEncode(body),
    );
    return _processResponse(response);
  }

  static Map<String, dynamic> _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        return {};
      }
    } else {
      throw Exception('API error: \${response.statusCode} \${response.body}');
    }
  }

  // Example convenience wrappers (adapt to your endpoints)
  static Future<List> fetchSectors() async {
    final r = await get('/sectors/');
    return r['results'] ?? r['data'] ?? [];
  }

  static Future<void> submitItem(Map item) async {
    await post('/items/', item);
  }

  static Future<bool> checkDuplicateById(String idNumber) async {
    try {
      final r = await get('/items/check-duplicate/?id=\$idNumber');
      return r['exists'] == true;
    } catch (_) {
      rethrow;
    }
  }
}
