import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../db/hive_manager.dart';
import '../models/user_profile.dart';
import 'token_storage.dart';

class AuthService extends ChangeNotifier {
  bool isLoggedIn = false;
  UserProfile? currentUser;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://bms.onastack.com/api",
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {"Content-Type": "application/json"},
    ),
  );

  AuthService() {
    autoLogin();
  }

  // ----------------------------------------------------------
  // LOGIN
  // ----------------------------------------------------------
  Future<String?> login(String username, String password) async {
    try {
      final response = await _dio.post(
        "/token/",
        data: {"username": username, "password": password},
      );

      final access = response.data["access"];
      final refresh = response.data["refresh"];

      if (access == null || refresh == null) {
        return "Invalid response";
      }

      await TokenStorage.saveTokens(access: access, refresh: refresh);

      // Load profile
      await fetchCurrentUser();

      isLoggedIn = true;
      notifyListeners();
      return null;
    } catch (e) {
      return "Invalid username or password";
    }
  }

  // ----------------------------------------------------------
  // AUTO LOGIN
  // ----------------------------------------------------------
  Future<void> autoLogin() async {
    final access = await TokenStorage.getAccessToken();

    if (access == null) {
      isLoggedIn = false;
      notifyListeners();
      return;
    }

    // Check if token expired
    if (JwtDecoder.isExpired(access)) {
      final refreshed = await refreshToken();
      if (!refreshed) {
        logout();
        return;
      }
    }

    await fetchCurrentUser();

    isLoggedIn = true;
    notifyListeners();
  }

  // ----------------------------------------------------------
  // REFRESH TOKEN
  // ----------------------------------------------------------
  Future<bool> refreshToken() async {
    try {
      final refresh = await TokenStorage.getRefreshToken();
      if (refresh == null) return false;

      final response =
          await _dio.post("/token/refresh/", data: {"refresh": refresh});

      final newAccess = response.data["access"];
      if (newAccess == null) return false;

      await TokenStorage.saveTokens(
          access: newAccess, refresh: refresh); // keep same refresh

      return true;
    } catch (e) {
      return false;
    }
  }

  // ----------------------------------------------------------
  // GET CURRENT USER
  // ----------------------------------------------------------
  Future<void> fetchCurrentUser() async {
    try {
      final access = await TokenStorage.getAccessToken();
      if (access == null) return;

      _dio.options.headers["Authorization"] = "Bearer $access";

      final response = await _dio.get("/current-user/");

      final user = UserProfile.fromJson(response.data);

      // Save offline
      final box = HiveManager.userProfile;
      await box.clear();
      await box.put("profile", user);

      currentUser = user;
    } catch (e) {
      print("Error fetching profile: $e");
    }
  }

  // ----------------------------------------------------------
  // LOGOUT
  // ----------------------------------------------------------
  Future<void> logout() async {
    await TokenStorage.clear();
    await HiveManager.userProfile.clear();

    isLoggedIn = false;
    currentUser = null;

    notifyListeners();
  }

  // ----------------------------------------------------------
  // GET AUTH HEADER FOR API CALLS
  // ----------------------------------------------------------
  Future<Map<String, dynamic>> getAuthHeader() async {
    String? access = await TokenStorage.getAccessToken();

    if (access == null || JwtDecoder.isExpired(access)) {
      // Try to refresh
      bool refreshed = await refreshToken();
      if (!refreshed) {
        logout();
        return {};
      }
      access = await TokenStorage.getAccessToken();
    }

    return {
      "Authorization": "Bearer $access",
      "Content-Type": "application/json"
    };
  }
}
