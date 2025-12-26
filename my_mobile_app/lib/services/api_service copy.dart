// lib/services/api_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/beneficiary.dart';
import 'token_service.dart';

class ApiService {
  ApiService();

  static const String _baseUrl = 'https://bms.onastack.com/api';

  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json',
  };

  /// Build headers, adding Authorization: Bearer <token> when needed.
  Future<Map<String, String>> _buildHeaders({bool withAuth = true}) async {
    final headers = <String, String>{..._jsonHeaders};

    if (withAuth) {
      final token = await TokenService.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool withAuth = true,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: query);
    final headers = await _buildHeaders(withAuth: withAuth);

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'PUT':
        return http.put(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'PATCH':
        return http.patch(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );
      case 'DELETE':
        return http.delete(uri, headers: headers);
      default:
        throw Exception('Unsupported HTTP method $method');
    }
  }

  // ---------------------------
  // AUTH
  // ---------------------------

  /// POST /api/token/
  /// Then GET /api/current-user/ and store username + email + groups
  Future<bool> login(String username, String password) async {
    final tokenUri = Uri.parse('$_baseUrl/token/');

    final tokenResp = await http.post(
      tokenUri,
      headers: _jsonHeaders,
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (tokenResp.statusCode != 200) {
      return false;
    }

    final Map<String, dynamic> tokenData =
        jsonDecode(tokenResp.body) as Map<String, dynamic>;

    final access = tokenData['access']?.toString();
    final refresh = tokenData['refresh']?.toString();

    if (access == null || refresh == null) {
      return false;
    }

    // Save tokens
    await TokenService.saveTokens(access: access, refresh: refresh);

    // Fetch current user info (username, email, groups)
    try {
      final meResp = await _request('GET', '/current-user/');

      if (meResp.statusCode == 200) {
        final Map<String, dynamic> me =
            jsonDecode(meResp.body) as Map<String, dynamic>;

        final uname = me['username']?.toString() ?? '';
        final email = me['email']?.toString() ?? '';
        final groupsRaw = me['groups'] ?? [];

        final groups = (groupsRaw is List)
            ? groupsRaw.map((e) => e.toString()).toList()
            : <String>[];

        await TokenService.saveUserInfo(
          username: uname,
          email: email,
          groups: groups,
        );
      }
    } catch (_) {
      // If /current-user/ fails we still keep tokens, user can still work
    }

    return true;
  }

  Future<void> logout() async {
    await TokenService.clear();
  }

  // ---------------------------
  // BENEFICIARIES
  // ---------------------------

  /// GET /api/beneficiaries/
  Future<List<Beneficiary>> fetchBeneficiaries() async {
    final resp = await _request('GET', '/beneficiaries/');

    if (resp.statusCode != 200) {
      throw Exception(
          'Failed to load beneficiaries (status ${resp.statusCode})');
    }

    final data = jsonDecode(resp.body);

    List<dynamic> items;
    if (data is List) {
      items = data;
    } else if (data is Map && data['results'] is List) {
      items = data['results'] as List;
    } else {
      throw Exception('Unexpected response format for beneficiaries');
    }

    return items
        .map((e) => Beneficiary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/beneficiaries/
  Future<Beneficiary> createBeneficiary(Map<String, dynamic> payload) async {
    final resp = await _request('POST', '/beneficiaries/', body: payload);

    if (resp.statusCode != 201 && resp.statusCode != 200) {
      throw Exception(
          'Failed to create beneficiary (status ${resp.statusCode})');
    }

    final Map<String, dynamic> data =
        jsonDecode(resp.body) as Map<String, dynamic>;
    return Beneficiary.fromJson(data);
  }

  /// PUT /api/beneficiaries/{id}/
  Future<Beneficiary> updateBeneficiary(
      int id, Map<String, dynamic> payload) async {
    final resp = await _request('PUT', '/beneficiaries/$id/', body: payload);

    if (resp.statusCode != 200) {
      throw Exception(
          'Failed to update beneficiary (status ${resp.statusCode})');
    }

    final Map<String, dynamic> data =
        jsonDecode(resp.body) as Map<String, dynamic>;
    return Beneficiary.fromJson(data);
  }

  // ---------------------------
  // DISTINCT DROPDOWNS
  // ---------------------------

  /// GET /api/distinct/ip-names/
  Future<List<String>> fetchDistinctIpNames() async {
    final resp = await _request('GET', '/distinct/ip-names/');

    if (resp.statusCode != 200) {
      throw Exception('Failed to load IP names (status ${resp.statusCode})');
    }

    final data = jsonDecode(resp.body);

    if (data is List) {
      return data.map((e) => e.toString()).toList();
    } else if (data is Map && data['results'] is List) {
      return (data['results'] as List).map((e) => e.toString()).toList();
    }

    throw Exception('Unexpected response format for ip-names');
  }

  /// GET /api/distinct/sectors/
  Future<List<String>> fetchDistinctSectors() async {
    final resp = await _request('GET', '/distinct/sectors/');

    if (resp.statusCode != 200) {
      throw Exception('Failed to load sectors (status ${resp.statusCode})');
    }

    final data = jsonDecode(resp.body);

    if (data is List) {
      return data.map((e) => e.toString()).toList();
    } else if (data is Map && data['results'] is List) {
      return (data['results'] as List).map((e) => e.toString()).toList();
    }

    throw Exception('Unexpected response format for sectors');
  }
}
