// api_service.dart

import 'package:dio/dio.dart';
import '../services/auth_service.dart';
import '../models/beneficiary.dart';
import '../db/hive_manager.dart';

class ApiService {
  final AuthService auth;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://bms.onastack.com/api",
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {"Content-Type": "application/json"},
    ),
  );

  ApiService(this.auth);

  Future<void> _setHeaders() async {
    final headers = await auth.getAuthHeader();
    _dio.options.headers = headers;
    //print("JWT Headers applied: ${_dio.options.headers}");
  }

  // ------------------------------------------------------------------
  // Helper to extract `results` list from pagination or non-paginated
  // ------------------------------------------------------------------
  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data.containsKey("results")) {
      return data["results"] as List;
    }
    throw Exception("Unexpected API format: $data");
  }

// --------------------------------------------------------------
// BACKWARD COMPATIBILITY: old method fetchBeneficiaries()
// Internally uses pagination and returns full list
// --------------------------------------------------------------

  Future<List<Beneficiary>> fetchAllBeneficiaries() async {
    List<Beneficiary> all = [];

    int page = 1;
    int lastPage = 1;

    while (true) {
      final res = await dio.get("/beneficiaries/", queryParameters: {
        "page": page,
      });

      final data = res.data;

      final count = data["count"] ?? 0;
      final pageSize = data["page_size"] ?? 100;

      lastPage = (count / pageSize).ceil();

      final List results = data["results"] ?? [];
      all.addAll(results.map((e) => Beneficiary.fromJson(e)));

      if (page >= lastPage) break;

      page++;
    }

    return all;
  }

  Future<List<Beneficiary>> fetchBeneficiaries() async {
    try {
      await _setHeaders();

      int limit = 100;
      int offset = 0;

      List<Beneficiary> all = [];

      while (true) {
        final page = await fetchBeneficiariesPage(limit: limit, offset: offset);

        final results = page["results"] as List;
        if (results.isEmpty) break;
        //print(results);

        all.addAll(results.map((e) => Beneficiary.fromJson(e)).toList());

        offset += limit;

        if (page["next"] == null) break;
      }

      return all;
    } catch (e) {
      print("OLD fetchBeneficiaries ERROR: $e");
      return [];
    }
  }

  // ------------------------------------------------------------------
  // PAGINATED fetch
  // limit = 100, offset = n*100
  // ------------------------------------------------------------------
  Future<Map<String, dynamic>> fetchBeneficiariesPage({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      await _setHeaders();

      final response = await _dio.get(
        "/beneficiaries/",
        queryParameters: {
          "limit": limit,
          "offset": offset,
        },
      );

      final data = response.data;
      //print(data);
      //print(_extractList(data));

      return {
        "count": data["count"] ?? 0,
        "next": data["next"],
        "results": _extractList(data),
      };
    } catch (e) {
      print("BENEFICIARY PAGINATED ERROR: $e");

      return {
        "count": 0,
        "next": null,
        "results": [],
      };
    }
  }

  // ------------------------------------------------------------------
  // DISTINCT IP NAMES
  // ------------------------------------------------------------------
  Future<List<String>> fetchDistinctIpNames() async {
    try {
      await _setHeaders();
      final res = await _dio.get("/distinct/ip-names/");

      final data = res.data;
      if (data is Map && data.containsKey("ip_names")) {
        final list = List<String>.from(data["ip_names"]);
        HiveManager.dropdownCache.put("ipnames", list);
        return list;
      }

      throw Exception("Unexpected IP Names format: $data");
    } catch (e) {
      print("IP NAMES ERROR: $e");
      return HiveManager.dropdownCache.get("ipnames")?.cast<String>() ?? [];
    }
  }

  // ------------------------------------------------------------------
  // DISTINCT SECTORS
  // ------------------------------------------------------------------
  Future<List<String>> fetchDistinctSectors() async {
    try {
      await _setHeaders();
      final res = await _dio.get("/distinct/sectors/");

      final data = res.data;
      if (data is Map && data.containsKey("sectors")) {
        final list = List<String>.from(data["sectors"]);
        HiveManager.dropdownCache.put("sectors", list);
        return list;
      }

      throw Exception("Unexpected sectors format: $data");
    } catch (e) {
      print("SECTORS ERROR: $e");
      return HiveManager.dropdownCache.get("sectors")?.cast<String>() ?? [];
    }
  }

  // ------------------------------------------------------------------
  // Duplicate check
  // ------------------------------------------------------------------
  Future<bool> checkDuplicateID(String idNumber) async {
    try {
      await _setHeaders();
      final url = "/beneficiaries/check-duplicate/$idNumber/";
      final res = await _dio.get(url);
      return res.data["exists"] ?? false;
    } catch (e) {
      print("DUP ERROR: $e");
      return false;
    }
  }

  // ------------------------------------------------------------------
  // CREATE
  // ------------------------------------------------------------------
  Future<int?> createBeneficiary(Beneficiary b) async {
    try {
      await _setHeaders();
      final res = await _dio.post("/beneficiaries/", data: b.toJson());
      return res.data["id"];
    } catch (e) {
      print("CREATE ERROR: $e");
      return null;
    }
  }

  // ------------------------------------------------------------------
  // UPDATE
  // ------------------------------------------------------------------
  Future<bool> updateBeneficiary(Beneficiary b) async {
    if (b.id == null) return false;

    try {
      await _setHeaders();
      await _dio.put("/beneficiaries/${b.id}/", data: b.toJson());
      return true;
    } catch (e) {
      print("UPDATE ERROR: $e");
      return false;
    }
  }

  // ------------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------------
  Future<bool> deleteBeneficiary(int id) async {
    try {
      await _setHeaders();
      await _dio.patch("/beneficiaries/$id/", data: {"Deleted": true});
      return true;
    } catch (e) {
      print("DELETE ERROR: $e");
      return false;
    }
  }
}
