import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../db/hive_manager.dart';
import '../models/beneficiary.dart';
import 'auth_service.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: "https://bms.onastack.com/api",
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: {"Content-Type": "application/json"},
    ),
  );

  final AuthService auth;

  ApiService(this.auth);

  // ---------------------------------------------------------
  // ATTACH AUTH HEADER
  // ---------------------------------------------------------
  Future<void> _setHeaders() async {
    _dio.options.headers = await auth.getAuthHeader();
  }

  // ---------------------------------------------------------
  // GET ALL BENEFICIARIES (ONLINE)
  // ---------------------------------------------------------
  Future<List<Beneficiary>> fetchBeneficiaries() async {
    try {
      await _setHeaders();
      final response = await _dio.get("/beneficiaries/");

      final data = response.data as List;

      return data.map((e) => Beneficiary.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------
  // GET DELETED BENEFICIARIES
  // ---------------------------------------------------------
  Future<List<Beneficiary>> fetchDeletedBeneficiaries() async {
    try {
      await _setHeaders();
      final res = await _dio.get("/beneficiaries/deleted/");

      return (res.data as List).map((e) => Beneficiary.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------------------------------------------------------
  // CREATE BENEFICIARY (POST)
  // ---------------------------------------------------------
  Future<int?> createBeneficiary(Beneficiary b) async {
    try {
      await _setHeaders();

      final res = await _dio.post(
        "/beneficiaries/",
        data: b.toJson(),
      );

      // Extract backend ID
      return res.data["id"];
    } catch (e) {
      return null;
    }
  }

  // ---------------------------------------------------------
  // UPDATE BENEFICIARY (PUT)
  // ---------------------------------------------------------
  Future<bool> updateBeneficiary(Beneficiary b) async {
    if (b.id == null) return false; // cannot update unknown id

    try {
      await _setHeaders();
      await _dio.put(
        "/beneficiaries/${b.id}/",
        data: b.toJson(),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------
  // SOFT DELETE BENEFICIARY (PATCH)
  // ---------------------------------------------------------
  Future<bool> deleteBeneficiary(int id) async {
    try {
      await _setHeaders();
      await _dio.patch("/beneficiaries/$id/delete/");
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------
  // DUPLICATE ID CHECK (REMOTE)
  // ---------------------------------------------------------
  Future<bool> checkDuplicateID(String idNumber) async {
    try {
      await _setHeaders();
      final res = await _dio.get("/beneficiaries/check-duplicate/",
          queryParameters: {"id_number": idNumber});
      return res.data["exists"] ?? false;
    } catch (e) {
      return false;
    }
  }

  // ---------------------------------------------------------
  // DISTINCT IP NAMES + SECTORS
  // ---------------------------------------------------------
  Future<List<String>> fetchDistinctIpNames() async {
    try {
      await _setHeaders();
      final res = await _dio.get("/beneficiaries/distinct/ipnames/");
      final list = (res.data as List).map((e) => e.toString()).toList();

      // cache offline
      HiveManager.dropdownCache.put("ipnames", list);

      return list;
    } catch (e) {
      // fallback offline
      return HiveManager.dropdownCache.get("ipnames")?.cast<String>() ?? [];
    }
  }

  Future<List<String>> fetchDistinctSectors() async {
    try {
      await _setHeaders();
      final res = await _dio.get("/beneficiaries/distinct/sectors/");
      final list = (res.data as List).map((e) => e.toString()).toList();

      // cache offline
      HiveManager.dropdownCache.put("sectors", list);

      return list;
    } catch (e) {
      // fallback offline
      return HiveManager.dropdownCache.get("sectors")?.cast<String>() ?? [];
    }
  }
}
