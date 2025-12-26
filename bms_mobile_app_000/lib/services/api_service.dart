import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/beneficiary.dart';
import '../models/api_response.dart';
import '../db/hive_manager.dart';
import 'auth_service.dart';

class ApiService {
  static const baseUrl = "https://bms.onastack.com/api";

  // auth must NOT be final so SyncService can update it
  AuthService? auth;

  ApiService(this.auth);

  // ---- UPDATE AUTH TOKEN WHEN USER LOGS IN ----
  void updateAuth(AuthService newAuth) {
    auth = newAuth;
  }

  // ---- HEADERS ----
  Map<String, String> _headers() {
    final token = auth?.accessToken ?? '';
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // ---- PAGINATION FETCH ----
  Future<List<Beneficiary>> fetchAllPaginated({
    bool deletedOnly = false,
  }) async {
    List<Beneficiary> all = [];
    int page = 1;

    while (true) {
      final res = await http.get(
        Uri.parse("$baseUrl/beneficiaries/?page=$page"),
        headers: _headers(),
      );

      print("PAGE $page STATUS: ${res.statusCode}");

      if (res.statusCode != 200) break;

      final Map<String, dynamic> json = jsonDecode(res.body);
      final List results = json["results"] ?? [];

      for (var item in results) {
        final isDeleted = item["Deleted"] == true;

        if ((deletedOnly && isDeleted) || (!deletedOnly && !isDeleted)) {
          all.add(Beneficiary.fromJson(item));
        }
      }

      if (json["next"] == null) break;
      page++;
    }

    print("TOTAL BENEFICIARIES FETCHED: ${all.length}");
    return all;
  }

  // ---- CREATE ----
  Future<ApiResponse> createBeneficiary(Beneficiary b) async {
    final res = await http.post(
      Uri.parse("$baseUrl/beneficiaries/"),
      headers: _headers(),
      body: jsonEncode(b.toJson()),
    );

    if (res.statusCode == 201) {
      return ApiResponse(success: true, data: jsonDecode(res.body));
    }

    return ApiResponse(success: false, message: res.body);
  }

  // ---- UPDATE ----
  Future<ApiResponse> updateBeneficiary(Beneficiary b) async {
    final res = await http.put(
      Uri.parse("$baseUrl/beneficiaries/${b.id}/"),
      headers: _headers(),
      body: jsonEncode(b.toJson()),
    );

    if (res.statusCode == 200) {
      return ApiResponse(success: true);
    }

    return ApiResponse(success: false, message: res.body);
  }

  // ---- DELETE ----
  Future<bool> deleteBeneficiary(String id) async {
    final res = await http.patch(
      Uri.parse("$baseUrl/beneficiaries/$id/"),
      headers: _headers(),
      body: jsonEncode({"Deleted": true}),
    );
    return res.statusCode == 200;
  }

  // ---- DROPDOWNS ----
  Future<List<String>> fetchDistinctIPNames() async {
    final res = await http.get(
      Uri.parse("$baseUrl/distinct/ip-names/"),
      headers: _headers(),
    );
    if (res.statusCode != 200) return [];

    return List<String>.from(jsonDecode(res.body)["ip_names"]);
  }

  Future<List<String>> fetchDistinctSectors() async {
    final res = await http.get(
      Uri.parse("$baseUrl/distinct/sectors/"),
      headers: _headers(),
    );
    if (res.statusCode != 200) return [];

    return List<String>.from(jsonDecode(res.body)["sectors"]);
  }
}
