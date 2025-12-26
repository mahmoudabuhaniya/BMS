import 'dart:convert';
import 'package:http/http.dart' as http;
import 'token_service.dart';
import '../models/beneficiary.dart';

class ApiService {
  static const String baseUrl = "https://bms.onastack.com/api";

  // -------------------------
  //  LOGIN (JWT)
  // -------------------------
  Future<bool> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/token/");

    final resp = await http.post(url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}));

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);

      await TokenService.storeTokens(
        access: data["access"],
        refresh: data["refresh"],
      );

      return true;
    }
    return false;
  }

  // -------------------------
  //  REFRESH TOKEN
  // -------------------------
  Future<bool> _refreshToken() async {
    final refresh = await TokenService.getRefresh();
    if (refresh == null) return false;

    final url = Uri.parse("$baseUrl/token/refresh/");

    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refresh}),
    );

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      await TokenService.storeTokens(
        access: data["access"],
        refresh: refresh,
      );
      return true;
    }

    return false;
  }

  // -------------------------
  //  PRIVATE GET WITH AUTO REFRESH
  // -------------------------
  Future<http.Response> _authorizedGet(String endpoint) async {
    final access = await TokenService.getAccess();
    var resp = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: {"Authorization": "Bearer $access"},
    );

    // Auto refresh on 401
    if (resp.statusCode == 401) {
      final ok = await _refreshToken();
      if (!ok) return resp;

      final newAccess = await TokenService.getAccess();
      resp = await http.get(
        Uri.parse("$baseUrl$endpoint"),
        headers: {"Authorization": "Bearer $newAccess"},
      );
    }

    return resp;
  }

  // -------------------------
  //  FETCH PROFILE
  // -------------------------
  Future<Map<String, dynamic>?> loadProfile() async {
    final resp = await _authorizedGet("/user/me/");
    if (resp.statusCode == 200) return jsonDecode(resp.body);
    return null;
  }

  // -------------------------
  //  FETCH BENEFICIARIES
  // -------------------------
  Future<List<Beneficiary>> fetchBeneficiaries() async {
    final resp = await _authorizedGet("/beneficiaries/");

    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list
          .map((e) => Beneficiary.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}
