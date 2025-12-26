import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

class TokenService {
  static const String _boxName = "auth_box";

  // Keys inside Hive
  static const String _accessKey = "access_token";
  static const String _refreshKey = "refresh_token";
  static const String _usernameKey = "username";
  static const String _firstNameKey = "firstName";
  static const String _lastNameKey = "lastName";
  static const String _groupsKey = "groups";

  static const String baseUrl = "https://bms.onastack.com";

  // -------------------------------------------------------
  // Ensure box exists
  // -------------------------------------------------------
  static Future<Box> _box() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  // -------------------------------------------------------
  // Save Access + Refresh Tokens
  // -------------------------------------------------------
  static Future<void> saveTokens(String access, String refresh) async {
    final box = await _box();
    await box.put(_accessKey, access);
    await box.put(_refreshKey, refresh);
  }

  static Future<String?> getAccessToken() async {
    final box = await _box();
    return box.get(_accessKey);
  }

  static Future<String?> getRefreshToken() async {
    final box = await _box();
    return box.get(_refreshKey);
  }

  // -------------------------------------------------------
  // Save logged-in user information
  // -------------------------------------------------------
  static Future<void> saveUserInfo({
    required String username,
    required String firstName,
    required String lastName,
    required List<String> groups,
  }) async {
    final box = await _box();
    await box.put(_usernameKey, username);
    await box.put(_firstNameKey, firstName);
    await box.put(_lastNameKey, lastName);
    await box.put(_groupsKey, groups);
  }

  static Future<String?> getUsername() async {
    final box = await _box();
    return box.get(_usernameKey);
  }

  static Future<List<String>> getGroups() async {
    final box = await _box();
    final data = box.get(_groupsKey);
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  // -------------------------------------------------------
  // Refresh JWT Token using /api/token/refresh/
  // -------------------------------------------------------
  static Future<bool> refreshTokensIfNeeded() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;

    final url = Uri.parse("$baseUrl/api/token/refresh/");

    final res = await http.post(url, body: {"refresh": refresh});

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data["access"] != null) {
        final box = await _box();
        await box.put(_accessKey, data["access"]);
        return true;
      }
    }
    return false;
  }

  // -------------------------------------------------------
  // Clear all tokens + user info (Logout)
  // -------------------------------------------------------
  static Future<void> clearAll() async {
    final box = await _box();
    await box.delete(_accessKey);
    await box.delete(_refreshKey);
    await box.delete(_usernameKey);
    await box.delete(_firstNameKey);
    await box.delete(_lastNameKey);
    await box.delete(_groupsKey);
  }
}
