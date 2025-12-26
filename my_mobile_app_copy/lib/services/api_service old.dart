// lib/services/api_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../models/beneficiary.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static const String baseUrl = 'https://bms.onastack.com';
  static const Duration requestTimeout = Duration(seconds: 20);
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // -------------------------------------------------------------
  // NEW: Extract distinct dropdown values from cached beneficiaries
  // -------------------------------------------------------------
  Future<Map<String, List<String>>> extractDistinctDropdownValues() async {
    final box = await Hive.openBox('beneficiariesBox');

    final Set<String> ipNames = {};
    final Set<String> sectors = {};

    for (final key in box.keys) {
      if (!key.toString().startsWith('page_')) continue;

      final cached = box.get(key);
      if (cached == null) continue;

      final List<dynamic> items =
          cached is List ? cached : [];

      for (final item in items) {
        final map = item is Beneficiary
            ? item.toJson()
            : Map<String, dynamic>.from(item);

        final b = Beneficiary.fromJson(map);

        if (b.ipName != null && b.ipName!.trim().isNotEmpty) {
          ipNames.add(b.ipName!.trim());
        }
        if (b.sector != null && b.sector!.trim().isNotEmpty) {
          sectors.add(b.sector!.trim());
        }
      }
    }

    return {
      "ip_names": ipNames.toList()..sort(),
      "sectors": sectors.toList()..sort(),
    };
  }

  // ---------------------------
  // Headers / Auth helpers
  // ---------------------------
  Future<Map<String, String>> _getHeaders() async {
    final accessToken = await storage.read(key: 'accessToken');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  // ---------------------------
  // Login / Token management
  // ---------------------------
  Future<bool> login(String username, String password) async {
    final uri = Uri.parse('$baseUrl/api/token/');
    final resp = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}))
        .timeout(requestTimeout);

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      await saveTokens(access: data['access'], refresh: data['refresh']);
      return true;
    } else if (resp.statusCode == 400 || resp.statusCode == 401) {
      return false;
    } else {
      throw ApiException('Login failed (${resp.statusCode})', resp.statusCode);
    }
  }

  Future<void> saveTokens({required String access, required String refresh}) async {
    await storage.write(key: 'accessToken', value: access);
    await storage.write(key: 'refreshToken', value: refresh);
  }

  Future<void> logout() async {
    await storage.delete(key: 'accessToken');
    await storage.delete(key: 'refreshToken');
    try {
      final box = await Hive.openBox('beneficiariesBox');
      await box.clear();
    } catch (_) {}
  }

  Future<void> refreshToken() async {
    final refreshToken = await storage.read(key: 'refreshToken');
    if (refreshToken == null) throw ApiException('No refresh token available');
    final uri = Uri.parse('$baseUrl/api/token/refresh/');
    final resp = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh': refreshToken}))
        .timeout(requestTimeout);

    if (resp.statusCode == 200) {
      final data = json.decode(resp.body);
      final newAccess = data['access'];
      if (newAccess == null) throw ApiException('Invalid refresh response');
      await storage.write(key: 'accessToken', value: newAccess);
    } else {
      await logout();
      throw ApiException('Failed to refresh token', resp.statusCode);
    }
  }

  // ---------------------------
  // Generic HTTP wrapper
  // ---------------------------
  Future<http.Response> _requestWithAuth(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? extraHeaders,
  }) async {
    final uri = Uri.parse('$baseUrl/$endpoint');
    Map<String, String> headers = await _getHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);

    Future<http.Response> doRequest() {
      switch (method.toUpperCase()) {
        case 'GET':
          return http.get(uri, headers: headers).timeout(requestTimeout);
        case 'POST':
          return http.post(uri, headers: headers, body: jsonEncode(body)).timeout(requestTimeout);
        case 'PUT':
          return http.put(uri, headers: headers, body: jsonEncode(body)).timeout(requestTimeout);
        case 'PATCH':
          return http.patch(uri, headers: headers, body: jsonEncode(body)).timeout(requestTimeout);
        case 'DELETE':
          return http.delete(uri, headers: headers).timeout(requestTimeout);
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }
    }

    http.Response resp = await doRequest();

    if (resp.statusCode == 401) {
      try {
        await refreshToken();
        headers = await _getHeaders();
        resp = await doRequest();
      } on ApiException {
        rethrow;
      }
    }

    return resp;
  }

  // ---------------------------
  // Beneficiaries: pagination + cache
  // ---------------------------
  Future<List<Beneficiary>> fetchBeneficiaries({
    int page = 1,
    int limit = 20,
    bool refresh = false,
  }) async {
    final box = await Hive.openBox('beneficiariesBox');
    final cacheKey = 'page_${page}_limit_${limit}';

    if (!refresh) {
      final cached = box.get(cacheKey);
      if (cached != null && cached is List && cached.isNotEmpty) {
        try {
          if (cached.first is Beneficiary) {
            return (cached as List).cast<Beneficiary>();
          } else {
            return (cached as List)
                .map((e) =>
                    Beneficiary.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          }
        } catch (_) {}
      }
    }

    final resp = await _requestWithAuth(
        'GET', 'api/beneficiaries/?page=$page&limit=$limit');

    if (resp.statusCode == 200) {
      final decoded = json.decode(resp.body);
      final List<dynamic> results =
          decoded is Map && decoded['results'] != null
              ? decoded['results']
              : (decoded is List ? decoded : []);
      final beneficiaries = results
          .map((e) =>
              Beneficiary.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      await box.put(
          cacheKey, beneficiaries.map((b) => b.toJson()).toList());
      return beneficiaries;
    } else {
      throw ApiException('Failed to fetch beneficiaries', resp.statusCode);
    }
  }

  Future<void> clearBeneficiariesCache() async {
    final box = await Hive.openBox('beneficiariesBox');
    final keys =
        box.keys.where((k) => k.toString().startsWith('page_')).toList();
    for (final k in keys) {
      await box.delete(k);
    }
  }

  // ---------------------------
  // Single beneficiary CRUD
  // ---------------------------
  Future<Beneficiary> getBeneficiary(int id) async {
    final resp =
        await _requestWithAuth('GET', 'api/beneficiaries/$id/');
    if (resp.statusCode == 200) {
      return Beneficiary.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);
    } else {
      throw ApiException('Failed to load beneficiary', resp.statusCode);
    }
  }

  Future<Beneficiary> createBeneficiary(Beneficiary b) async {
    final body = b.toApiJson();
    final resp =
        await _requestWithAuth('POST', 'api/beneficiaries/', body: body);
    if (resp.statusCode == 201 || resp.statusCode == 200) {
      await clearBeneficiariesCache();
      return Beneficiary.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);
    } else {
      throw ApiException(
          'Failed to create beneficiary: ${resp.body}', resp.statusCode);
    }
  }

  Future<Beneficiary> updateBeneficiary(int id, Beneficiary b) async {
    final body = b.toApiJson();
    final resp =
        await _requestWithAuth('PUT', 'api/beneficiaries/$id/', body: body);
    if (resp.statusCode == 200) {
      await clearBeneficiariesCache();
      return Beneficiary.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);
    } else {
      throw ApiException(
          'Failed to update beneficiary: ${resp.body}', resp.statusCode);
    }
  }

  Future<void> deleteBeneficiary(int id) async {
    final resp =
        await _requestWithAuth('DELETE', 'api/beneficiaries/$id/');
    if (resp.statusCode == 204 || resp.statusCode == 200) {
      await clearBeneficiariesCache();
      return;
    } else {
      throw ApiException('Failed to delete beneficiary', resp.statusCode);
    }
  }

  Future<bool> checkBeneficiaryExists(String idNumber) async {
  final response = await _requestWithAuth('GET', 'api/beneficiaries/?id_number=$idNumber');
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List;
    return data.isNotEmpty;
  } else {
    throw Exception('Failed to check beneficiary');
  }
  }


  // ---------------------------
  // Utility
  // ---------------------------
  Future<List<Beneficiary>> fetchBeneficiariesForce(
          {int page = 1, int limit = 20}) =>
      fetchBeneficiaries(page: page, limit: limit, refresh: true);

  Future<void> clearAllCache() async {
    final box = await Hive.openBox('beneficiariesBox');
    await box.clear();
  }
}
