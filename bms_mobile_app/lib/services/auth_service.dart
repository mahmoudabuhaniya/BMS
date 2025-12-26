import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';

import '../models/user_profile.dart';
import '../db/hive_manager.dart';

class AuthService extends ChangeNotifier {
  // -------------------------------------------------------------
  // STATIC (GLOBAL ACCESS)
  // -------------------------------------------------------------
  static UserProfile? _currentUser;
  static String? _accessToken;
  static String? _refreshToken;

  // Global getters
  UserProfile? get currentUser => _currentUser;
  static UserProfile? get currentUserStatic => _currentUser;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  bool get isLoggedIn => _currentUser != null;

  final Dio dio = Dio();

  // -------------------------------------------------------------
  // CONSTRUCTOR — Base API URL
  // -------------------------------------------------------------
  AuthService() {
    dio.options.baseUrl = "https://bms.onastack.com/api/";
    dio.options.headers = {
      "Content-Type": "application/json",
    };

    // Add interceptor for auto-refresh
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) async {
          if (e.response?.statusCode == 401 &&
              _refreshToken != null &&
              _accessToken != null) {
            print("⚠️ 401 detected → attempting token refresh…");

            final ok = await attemptTokenRefresh();
            if (ok) {
              // Retry original request
              final req = e.requestOptions;
              req.headers["Authorization"] = "Bearer $_accessToken";

              try {
                final clone = await dio.fetch(req);
                return handler.resolve(clone);
              } catch (_) {}
            }

            // Refresh failed → logout
            print("❌ Token refresh failed → logging out");
            await logout();
          }

          return handler.next(e);
        },
      ),
    );
  }

  // -------------------------------------------------------------
  // Refresh Token
  // -------------------------------------------------------------

  // -------------------------------------------------------------
  // LOAD SESSION FROM HIVE
  // -------------------------------------------------------------
  Future<void> loadSavedUser() async {
    final profileBox = HiveManager.userProfile;
    if (profileBox.isNotEmpty) {
      _currentUser = profileBox.getAt(0);
    }

    final tokenBox = Hive.box("tokens");
    _accessToken = tokenBox.get("access");
    _refreshToken = tokenBox.get("refresh");

    notifyListeners();
  }

  // -------------------------------------------------------------
  // LOGIN
  // -------------------------------------------------------------
  Future<bool> login(String username, String password) async {
    try {
      final res = await dio.post(
        "token/",
        data: FormData.fromMap({
          "username": username,
          "password": password,
        }),
      );

      if (res.statusCode == 200) {
        _accessToken = res.data["access"];
        _refreshToken = res.data["refresh"];

        // Store tokens
        final tokenBox = Hive.box("tokens");
        await tokenBox.put("access", _accessToken);
        await tokenBox.put("refresh", _refreshToken);

        // Fetch profile
        final profileRes = await dio.get(
          "current-user/",
          options: Options(headers: {"Authorization": "Bearer $_accessToken"}),
        );

        final profile = UserProfile.fromJson(profileRes.data);

        final box = HiveManager.userProfile;
        await box.clear();
        await box.add(profile);

        _currentUser = profile;

        notifyListeners();
        return true;
      }
    } catch (e) {
      if (e is DioException) {
        print("❌ LOGIN STATUS: ${e.response?.statusCode}");
        print("❌ LOGIN DATA: ${e.response?.data}");
      } else {
        print("❌ LOGIN ERROR: $e");
      }
    }

    return false;
  }

  // -------------------------------------------------------------
  // TOKEN REFRESH
  // -------------------------------------------------------------
  Future<bool> attemptTokenRefresh() async {
    if (_refreshToken == null) return false;

    try {
      final res = await dio.post("token/refresh/", data: {
        "refresh": _refreshToken,
      });

      if (res.statusCode == 200) {
        _accessToken = res.data["access"];
        final tokenBox = Hive.box("tokens");
        await tokenBox.put("access", _accessToken);
        print("✅ Token successfully refreshed!");
        return true;
      }
    } catch (e) {
      print("❌ REFRESH ERROR: $e");
    }

    return false;
  }

  // -------------------------------------------------------------
  // LOGOUT
  // -------------------------------------------------------------
  Future<void> logout() async {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;

    await HiveManager.userProfile.clear();
    await Hive.box("tokens").clear();

    notifyListeners();
  }
}
