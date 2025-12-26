//token_storage.dart

import 'package:hive/hive.dart';

class TokenStorage {
  static const String tokenBoxName = "auth_tokens";

  static Future<Box> _openBox() async {
    if (!Hive.isBoxOpen(tokenBoxName)) {
      return await Hive.openBox(tokenBoxName);
    }
    return Hive.box(tokenBoxName);
  }

  // -----------------------
  // Save tokens
  // -----------------------
  static Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    final box = await _openBox();
    await box.put("access", access);
    await box.put("refresh", refresh);
  }

  // -----------------------
  // Load tokens
  // -----------------------
  static Future<String?> getAccessToken() async {
    final box = await _openBox();
    return box.get("access");
  }

  static Future<String?> getRefreshToken() async {
    final box = await _openBox();
    return box.get("refresh");
  }

  // -----------------------
  // Clear (logout)
  // -----------------------
  static Future<void> clear() async {
    final box = await _openBox();
    await box.clear();
  }
}
