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

    _setHeaders();

    // ------------------------------
    // AUTO LOGOUT ON TOKEN EXPIRE
    // ------------------------------
    dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          print("❌ 401 Unauthorized → logging out");
          await auth.logout();
        }
        return handler.next(e);
      },
    ));
  }

  // ------------------------------
  // INTERNAL: Set Main Headers
  // ------------------------------
  void _setHeaders() {
    dio.options.headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer ${auth.accessToken}"
    };
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
        data: jsonEncode(body),
        options: Options(headers: {
          "Authorization": "Bearer ${auth.accessToken}",
        }),
      );

      return res.data;
    } catch (e) {
      print("❌ Orchestration Error ($action): $e");
      return null;
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
  Future<Map<String, dynamic>?> fullSync() async {
    try {
      final res = await dio.get(
        "mobile/sync/full/",
        options: Options(headers: {
          "Authorization": "Bearer ${auth.accessToken}",
        }),
      );
      return res.data;
    } catch (e) {
      print("❌ Full Sync Error: $e");
      return null;
    }
  }

  // INCREMENTAL
  Future<Map<String, dynamic>?> incrementalSync(String updatedAfter) async {
    try {
      final res = await dio.get(
        "mobile/sync/incremental/",
        queryParameters: {"updated_after": updatedAfter},
        options: Options(headers: {
          "Authorization": "Bearer ${auth.accessToken}",
        }),
      );
      return res.data;
    } catch (e) {
      print("❌ Incremental Sync Error: $e");
      return null;
    }
  }

  // ============================================================
  // 📌 3 — LOOKUPS
  // ============================================================

  Future<List<String>> fetchIPNames() async {
    try {
      final res = await dio.get(
        "mobile/lookups/ipnames/",
        options: Options(headers: {
          "Authorization": "Bearer ${auth.accessToken}",
        }),
      );

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
      final res = await dio.get(
        "mobile/lookups/sectors/",
        options: Options(headers: {
          "Authorization": "Bearer ${auth.accessToken}",
        }),
      );

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

    payload.remove("localId");

    payload.updateAll((key, value) {
      if (value == "" || value == " " || value == "null") return null;
      return value;
    });

    return payload;
  }
}
