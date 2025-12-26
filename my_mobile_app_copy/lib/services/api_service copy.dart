// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'token_service.dart';
import '../models/beneficiary.dart';

class ApiService {
  static const String baseUrl = "https://bms.onastack.com/api";

  // -----------------------------
  // GENERIC REQUEST WRAPPER
  // -----------------------------
  Future<dynamic> _request(String method, String endpoint, {Map? data}) async {
    final token = await TokenService.getToken();

    final url = Uri.parse("$baseUrl$endpoint");
    final headers = {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };

    http.Response response;

    if (method == "GET") {
      response = await http.get(url, headers: headers);
    } else if (method == "POST") {
      response = await http.post(url, headers: headers, body: jsonEncode(data));
    } else if (method == "PUT") {
      response = await http.put(url, headers: headers, body: jsonEncode(data));
    } else {
      throw Exception("Unsupported HTTP method");
    }

    if (response.statusCode == 401) {
      await TokenService.clearToken();
      await TokenService.clearUserInfo();
      throw Exception("Unauthorized");
    }

    if (response.statusCode >= 400) {
      throw Exception("Server error: ${response.body}");
    }

    if (response.body.isEmpty) return null;

    return jsonDecode(response.body);
  }

  // -----------------------------
  // AUTH
  // -----------------------------
  Future<Map<String, dynamic>> login(String username, String password) async {
    final data = {"username": username, "password": password};
    final response = await _request("POST", "/token/", data: data);
    return response;
  }

  Future<void> logout() async {
    await TokenService.clearToken();
    await TokenService.clearUserInfo();
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    return await _request("GET", "/current-user/");
  }

  // -----------------------------
  // BENEFICIARY CRUD
  // -----------------------------
  Future<List<Beneficiary>> fetchBeneficiaries() async {
    final data = await _request("GET", "/beneficiaries/");
    return (data as List).map((json) => Beneficiary.fromJson(json)).toList();
  }

  Future<Beneficiary> createBeneficiary(Map<String, dynamic> formData) async {
    final result = await _request("POST", "/beneficiaries/", data: formData);
    return Beneficiary.fromJson(result);
  }

  Future<Beneficiary> updateBeneficiary(
      int id, Map<String, dynamic> data) async {
    final result = await _request("PUT", "/beneficiaries/$id/", data: data);
    return Beneficiary.fromJson(result);
  }

  Future<bool> checkDuplicate(String idNumber) async {
    final result =
        await _request("GET", "/beneficiaries/check-duplicate/$idNumber/");
    return result["exists"] == true;
  }

  Future<bool> submitItem(Map<String, dynamic> data,
      {Beneficiary? existing}) async {
    final token = await TokenService.getToken();
    if (token == null) throw Exception("No token available");

    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
    };

    late String url;
    late http.Response response;

    if (existing == null) {
      // CREATE
      url = "${baseUrl}/beneficiaries/";
      response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      );
    } else {
      // UPDATE
      url = "${baseUrl}/beneficiaries/${existing.id}/";
      response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: json.encode(data),
      );
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    }

    throw Exception(
        "Failed to submit item: ${response.statusCode} ${response.body}");
  }
}
