import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/beneficiary.dart';
import 'token_service.dart';

class ApiService {
  // TODO: change this to your REAL base URL
  // e.g. "https://bms.onastack.com"
  static const String baseUrl = "https://bms.onastack.com";

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Future<Map<String, String>> _authHeaders() async {
    final token = await TokenService.getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ---------------------------
  // AUTH
  // ---------------------------

  Future<Map<String, dynamic>?> login({
    required String username,
    required String password,
  }) async {
    // Adjust endpoint if different (e.g. /api/token/)
    final url = _uri('/api/token/');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final access = data['access'] as String?;
      final refresh = data['refresh'] as String?;
      if (access != null) {
        await TokenService.saveTokens(access, refresh);
      }
      return data;
    } else {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    final headers = await _authHeaders();
    final url = _uri('/api/current-user');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> logout() async {
    // If you have a logout endpoint, call it here.
    // For now we just clear local tokens.
    await TokenService.clearAll();
  }

  // ---------------------------
  // BENEFICIARIES
  // ---------------------------

  Future<List<Beneficiary>> fetchBeneficiaries(
      {bool showDeleted = false}) async {
    final headers = await _authHeaders();

    // Adjust query param name to match your DRF view
    final url = _uri(
      showDeleted
          ? '/api/beneficiaries/?deleted=true'
          : '/api/beneficiaries/?deleted=false',
    );

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is List) {
        return body
            .map((e) => Beneficiary.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (body is Map && body['results'] is List) {
        // DRF pagination style
        return (body['results'] as List)
            .map((e) => Beneficiary.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    }

    return [];
  }

  Future<Beneficiary?> createBeneficiary(Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final url = _uri('/api/beneficiaries/');

    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      return Beneficiary.fromJson(body);
    }
    throw Exception('Failed to create beneficiary (${response.statusCode})');
  }

  Future<Beneficiary?> updateBeneficiary(
      int id, Map<String, dynamic> data) async {
    final headers = await _authHeaders();
    final url = _uri('/api/beneficiaries/$id/');

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body) as Map<String, dynamic>;
      return Beneficiary.fromJson(body);
    }
    throw Exception('Failed to update beneficiary (${response.statusCode})');
  }

  // ---------------------------
  // DISTINCT DROPDOWNS
  // ---------------------------

  Future<List<String>> fetchDistinctIpNames() async {
    final headers = await _authHeaders();
    final url = _uri('/api/distinct/ip-names/');

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is List) {
        return body.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  Future<List<String>> fetchDistinctSectors() async {
    final headers = await _authHeaders();
    final url = _uri('/api/distinct/sectors/');

    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is List) {
        return body.map((e) => e.toString()).toList();
      }
    }
    return [];
  }

  // ---------------------------
  // DUPLICATE CHECK
  // ---------------------------

  Future<bool> checkDuplicateId(String idNumber, {int? existingId}) async {
    if (idNumber.trim().isEmpty) return false;

    final headers = await _authHeaders();
    final params = {
      'id_number': idNumber.trim(),
      if (existingId != null) 'exclude_id': existingId.toString(),
    };
    final uri = _uri('/api/beneficiaries/check-duplicate/')
        .replace(queryParameters: params);

    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body is Map<String, dynamic>) {
        return body['exists'] == true;
      }
    }
    return false;
  }
}
