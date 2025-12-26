import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/beneficiary.dart';
import 'token_service.dart';

class ApiService {
  static const String baseUrl = "https://bms.onastack.com";

  // ------------------------------------------------
  // Helper: Get Authorization header
  // ------------------------------------------------
  Future<Map<String, String>> _headers() async {
    final token = await TokenService.getAccessToken();
    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  // ------------------------------------------------
  // Helper: Check Internet Connectivity
  // ------------------------------------------------
  Future<bool> _hasConnection() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ------------------------------------------------
  // JWT Login: POST /api/token/
  // ------------------------------------------------
  Future<bool> login(String username, String password) async {
    final url = Uri.parse("$baseUrl/api/token/");
    final res = await http.post(
      url,
      body: {"username": username, "password": password},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      final access = data["access"];
      final refresh = data["refresh"];

      await TokenService.saveTokens(access, refresh);

      // Load user info
      await getCurrentUser();

      return true;
    }
    return false;
  }

  // ------------------------------------------------
  // JWT Current User
  // ------------------------------------------------
  Future<Map<String, dynamic>?> getCurrentUser() async {
    await TokenService.refreshTokensIfNeeded();

    final url = Uri.parse("$baseUrl/api/current-user/");

    final res = await http.get(url, headers: await _headers());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      await TokenService.saveUserInfo(
        username: data["username"] ?? "",
        firstName: data["first_name"] ?? "",
        lastName: data["last_name"] ?? "",
        groups: (data["groups"] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
      );

      return data;
    }
    return null;
  }

  // ------------------------------------------------
  // GET Beneficiaries (List)
  // ------------------------------------------------
  Future<List<Beneficiary>> fetchBeneficiaries() async {
    await TokenService.refreshTokensIfNeeded();

    final url = Uri.parse("$baseUrl/api/beneficiaries/");

    final res = await http.get(url, headers: await _headers());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      return (data as List<dynamic>)
          .map((e) => Beneficiary.fromJson(e))
          .toList();
    }

    return [];
  }

  // ------------------------------------------------
  // GET Distinct IP Names
  // ------------------------------------------------
  Future<List<String>> getDistinctIpNames() async {
    await TokenService.refreshTokensIfNeeded();

    final url = Uri.parse("$baseUrl/api/distinct/ip-names/");

    final res = await http.get(url, headers: await _headers());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      return (data["ip_names"] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }
    return [];
  }

  // ------------------------------------------------
  // GET Distinct Sectors
  // ------------------------------------------------
  Future<List<String>> getDistinctSectors() async {
    await TokenService.refreshTokensIfNeeded();

    final url = Uri.parse("$baseUrl/api/distinct/sectors/");

    final res = await http.get(url, headers: await _headers());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      return (data["sectors"] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    }
    return [];
  }

  // ------------------------------------------------
  // PUSH Create (Sync from queue)
  // ------------------------------------------------
  Future<bool> pushCreate(Beneficiary b) async {
    if (!await _hasConnection()) return false;

    await TokenService.refreshTokensIfNeeded();

    final url = Uri.parse("$baseUrl/api/beneficiaries/");
    final res = await http.post(
      url,
      headers: await _headers(),
      body: jsonEncode(b.toJson()),
    );

    return res.statusCode == 201;
  }

  // ------------------------------------------------
  // PUSH Update
  // ------------------------------------------------
  Future<bool> pushUpdate(Beneficiary b) async {
    if (!await _hasConnection()) return false;

    await TokenService.refreshTokensIfNeeded();

    if (b.id == null) return false;

    final url = Uri.parse("$baseUrl/api/beneficiaries/${b.id}/");

    final res = await http.put(
      url,
      headers: await _headers(),
      body: jsonEncode(b.toJson()),
    );

    return res.statusCode == 200;
  }

  // ------------------------------------------------
  // PUSH Delete
  // ------------------------------------------------
  Future<bool> pushDelete(Beneficiary b) async {
    if (!await _hasConnection()) return false;

    await TokenService.refreshTokensIfNeeded();

    if (b.id == null) return false;

    final url = Uri.parse("$baseUrl/api/beneficiaries/${b.id}/delete/");

    final res = await http.patch(url, headers: await _headers());

    return res.statusCode == 200;
  }
}
