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
    dio.options.headers = {
      "Authorization": "Bearer ${auth.accessToken}",
      "Content-Type": "application/json",
    };
  }

  // ------------------------------------------------------
  // PAGINATED SINGLE PAGE
  // ------------------------------------------------------
  Future<Map<String, dynamic>> fetchBeneficiariesPage({
    required int page,
    required int limit,
    required String? updatedAfter,
  }) async {
    final res = await dio.get(
      "beneficiaries/",
      options: Options(
        headers: {"Authorization": "Bearer ${auth.accessToken}"},
      ),
      queryParameters: {
        "page": page,
        "page_size": limit,
        if (updatedAfter != null) "updated_after": updatedAfter,
      },
    );

    return {
      "count": res.data["count"],
      "results": res.data["results"],
      "page": res.data["page"],
      "page_size": res.data["page_size"],
      "server_time": res.data["server_time"],
    };
  }

  // ------------------------------------------------------
  // CREATE BENEFICIARY
  // ------------------------------------------------------
  Future<int?> createBeneficiary(Beneficiary b) async {
    try {
      final payload = b.toJson()
        ..remove("id")
        ..remove("localId");

      payload["created_by"] = auth.currentUser?.username;
      payload["Submission_Time"] = DateTime.now().toIso8601String();

      final res = await dio.post("beneficiaries/",
          options: Options(
            headers: {"Authorization": "Bearer ${auth.accessToken}"},
          ),
          data: jsonEncode(payload));

      return res.data["id"];
    } catch (e) {
      print("CREATE ERROR: $e");
      return null;
    }
  }

  // ------------------------------------------------------
  // UPDATE BENEFICIARY
  // ------------------------------------------------------
  Future<bool> updateBeneficiary(Beneficiary b) async {
    if (b.id == null) return false;

    try {
      final res = await dio.put(
        "beneficiaries/${b.id}/",
        options: Options(
          headers: {"Authorization": "Bearer ${auth.accessToken}"},
        ),
        data: jsonEncode(b.toJson()),
      );

      return res.statusCode == 200;
    } catch (e) {
      print("UPDATE ERROR: $e");
      return false;
    }
  }

  // ------------------------------------------------------
  // DROPDOWN FETCH
  // ------------------------------------------------------
  Future<List<String>> fetchIPNames() async {
    try {
      final res = await dio.get(
        "distinct/ip-names/",
        options: Options(
          headers: {"Authorization": "Bearer ${auth.accessToken}"},
        ),
      );

      print("IP Response: ${res.data}");

      // Extract the list properly
      final list = List<String>.from(res.data["ip_names"]);

      HiveManager.dropdownCache.put("ipnames", list);
      return list;
    } catch (e) {
      print("IP ERROR: $e");
      return HiveManager.dropdownCache.get("ipnames")?.cast<String>() ?? [];
    }
  }

  Future<List<String>> fetchSectors() async {
    try {
      final res = await dio.get(
        "distinct/sectors/",
        options: Options(
          headers: {"Authorization": "Bearer ${auth.accessToken}"},
        ),
      );

      print("Sectors Response: ${res.data}");

      // Extract the list properly
      final list = List<String>.from(res.data["sectors"]);

      HiveManager.dropdownCache.put("sectors", list);
      return list;
    } catch (e) {
      print("SECTOR ERROR: $e");
      return HiveManager.dropdownCache.get("sectors")?.cast<String>() ?? [];
    }
  }

  Future<List<Beneficiary>> fetchBeneficiariesAfterId(int lastId) async {
    final res = await dio.get(
      "/beneficiaries/",
      queryParameters: {
        "id__gt": lastId,
        "limit": 1000,
      },
    );

    return (res.data["results"] as List)
        .map((e) => Beneficiary.fromJson(e))
        .toList();
  }

  Future<Map<String, dynamic>> fetchBeneficiariesDelta({
    required int lastId,
    required int page,
    required int limit,
    required String updatedSince, // Add this
  }) async {
    try {
      final res = await dio.get(
        "beneficiaries/",
        options: Options(
          headers: {"Authorization": "Bearer ${auth.accessToken}"},
        ),
        queryParameters: {
          "id__gt": lastId,
          "page": page,
          "page_size": limit,
          "updated_since": updatedSince, // Add this param
        },
      );

      return {
        "count": res.data["count"],
        "results": res.data["results"],
        "page": res.data["page"] ?? page, // fallback
        "page_size": res.data["page_size"] ?? limit,
      };
    } catch (e) {
      print("❌ Error in fetchBeneficiariesDelta: $e");
      rethrow;
    }
  }
}
