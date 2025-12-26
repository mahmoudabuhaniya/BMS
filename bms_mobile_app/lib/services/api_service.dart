import 'dart:convert';
import 'package:dio/dio.dart';

import '../models/beneficiary.dart';
import '../services/auth_service.dart';
import '../db/hive_manager.dart';

class ApiService {
  final Dio dio = Dio();
  final AuthService auth;

  ApiService(this.auth) {
    dio.options.baseUrl = "https://bms.onastack.com/api/";
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);

    // Prefer Accept globally; Authorization is injected by interceptor
    dio.options.headers = {
      "Accept": "application/json",
    };

    // Interceptor to inject Authorization and handle 401
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = auth.accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            print('🔐 401 received — attempting token refresh');

            final refreshed = await auth.attemptTokenRefresh();

            if (refreshed) {
              print('✅ Token refreshed — retrying request');
              final clone = await dio.request(
                e.requestOptions.path,
                data: e.requestOptions.data,
                queryParameters: e.requestOptions.queryParameters,
                options: Options(
                  method: e.requestOptions.method,
                  headers: e.requestOptions.headers,
                ),
              );
              return handler.resolve(clone);
            }

            print('⛔ Token refresh failed — forcing logout');
            await auth.logout();
            return handler.reject(e);
          }

          return handler.reject(e);
        },
      ),
    );
  }

  // ============================================================
  // 🔥 1 — UNIVERSAL ORCHESTRATION ENDPOINT
  // ============================================================
  Future<Map<String, dynamic>?> orchestrateAction({
    required String action,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final body = {
        "action": action,
        "payload": payload,
      };

      final res = await dio.post(
        "mobile/orchestrate/",
        data: body,
      );

      return res.data;
    } catch (e) {
      print("❌ Orchestration Error ($action): $e");
      if (e is DioException && e.response?.statusCode == 401) {
        print('⛔ Orchestration blocked — auth failure');
        return {"success": false, "error": "Authentication failed"};
      }
      rethrow;
    }
  }

  // ------------------------------
  // CREATE
  // ------------------------------
  Future<Map<String, dynamic>?> createBeneficiary(Beneficiary b) async {
    return await orchestrateAction(
      action: "create",
      payload: _preparePayload(b),
    );
  }

  // ------------------------------
  // UPDATE
  // ------------------------------
  Future<Map<String, dynamic>?> updateBeneficiary(Beneficiary b) async {
    if (b.id == null) return null;

    return await orchestrateAction(
      action: "update",
      payload: _preparePayload(b),
    );
    // If your API expects the id separately, include it:
    // payload["id"] = b.id!;
  }

  // ------------------------------
  // DELETE (soft delete)
  // ------------------------------
  Future<Map<String, dynamic>?> deleteBeneficiary({
    required int id,
    required String deletedBy,
  }) async {
    return await orchestrateAction(
      action: "delete",
      payload: {
        "id": id,
        "deleted_by": deletedBy,
      },
    );
  }

  // ------------------------------
  // RESTORE
  // ------------------------------
  Future<Map<String, dynamic>?> restoreBeneficiary({
    required int id,
    required String undeletedBy,
  }) async {
    return await orchestrateAction(
      action: "restore",
      payload: {
        "id": id,
        "undeleted_by": undeletedBy,
      },
    );
  }

  // ============================================================
  // 🔄 2 — SYNC ENDPOINTS
  // ============================================================

  // FULL SYNC
  Future<Map<String, dynamic>?> fullSync({
    required int page,
    required int pageSize,
  }) async {
    try {
      final res = await dio.post(
        "mobile/sync/full/",
        data: {
          "page": page,
          "page_size": pageSize,
        },
      );
      return res.data;
    } catch (e) {
      print("❌ Full Sync Error: $e");
      return null;
    }
  }

  // INCREMENTAL
  Future<Map<String, dynamic>?> incrementalSync({
    required String updatedAfter,
    required int page,
    required int pageSize,
  }) async {
    try {
      final res = await dio.post(
        "mobile/sync/incremental/",
        data: {
          "updated_after": updatedAfter,
          "page": page,
          "page_size": pageSize,
        },
      );

      return res.data;
    } catch (e) {
      print("❌ Incremental Sync Error: $e");
      return null;
    }
  }

  // ============================================================
  // 📌 3 — LOOKUPS (use relative URLs)
  // ============================================================

  Future<List<String>> fetchIPNames() async {
    try {
      final res = await dio.get("mobile/lookups/ipnames/");
      final list = List<String>.from(res.data["ipnames"]);
      HiveManager.dropdownCache.put("ipnames", list);
      return list;
    } catch (e) {
      print("❌ IP Lookup Error: $e");
      return HiveManager.dropdownCache.get("ipnames")?.cast<String>() ?? [];
    }
  }

  Future<List<String>> fetchSectors() async {
    try {
      final res = await dio.get("mobile/lookups/sectors/");
      final list = List<String>.from(res.data["sectors"]);
      HiveManager.dropdownCache.put("sectors", list);
      return list;
    } catch (e) {
      print("❌ Sector Lookup Error: $e");
      return HiveManager.dropdownCache.get("sectors")?.cast<String>() ?? [];
    }
  }

  // ============================================================
  // 🧠 INTERNAL PAYLOAD CLEANER
  // ============================================================
  Map<String, dynamic> _preparePayload(Beneficiary b) {
    final payload = b.toJson();

    // Remove local-only fields
    payload.remove("localId");

    // Normalize empty-ish values to null
    payload.updateAll((key, value) {
      if (value == "" || value == " " || value == "null") return null;
      return value;
    });

    return payload;
  }
}
