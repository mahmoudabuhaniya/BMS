import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../models/login_response.dart';
import '../models/user_profile.dart';
import '../db/hive_manager.dart';

class AuthService extends ChangeNotifier {
  static const baseUrl = "https://bms.onastack.com/api";

  String? _access;
  String? _refresh;
  UserProfile? currentUser;

  String? get accessToken => _access;

  bool get isLoggedIn => _access != null;

  // ----------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------
  Future<String?> login(String username, String password) async {
    try {
      final res = await http.post(
        Uri.parse("$baseUrl/token/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (res.statusCode != 200) {
        return "Invalid username or password";
      }

      final json = jsonDecode(res.body);

      final login = LoginResponse.fromJson(json);
      _access = login.access;
      _refresh = login.refresh;

      // Save to Hive
      final box = Hive.box("auth");

      await box.put("access", _access);
      await box.put("refresh", _refresh);

      // Load user profile
      await loadProfile();

      notifyListeners();
      return null;
    } catch (e) {
      return "Login failed: $e";
    }
  }

  // ----------------------------------------------------------
  // LOAD PROFILE
  // ----------------------------------------------------------
  Future<void> loadProfile() async {
    if (_access == null) return;

    final res = await http.get(
      Uri.parse("$baseUrl/current-user/"),
      headers: {"Authorization": "Bearer $_access"},
    );

    print("PROFILE STATUS: ${res.statusCode}");
    print("PROFILE RAW: ${res.body}");

    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      currentUser = UserProfile.fromJson(json);
      notifyListeners();
    }
  }

  // ----------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------
  Future<void> logout(BuildContext context) async {
    final box = Hive.box("auth");
    await box.clear();

    _access = null;
    _refresh = null;
    currentUser = null;

    notifyListeners();

    Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
  }
}
