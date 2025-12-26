import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'beneficiary.g.dart';

@HiveType(typeId: 1)
class Beneficiary extends HiveObject {
  // ---------------------------
  // PRIMARY KEYS
  // ---------------------------
  @HiveField(0)
  int? id; // Django PK

  @HiveField(1)
  int? localId;

  // ---------------------------
  // DJANGO MODEL FIELDS
  // ---------------------------

  @HiveField(2)
  String? recordId;

  @HiveField(3)
  String? inFormId;

  @HiveField(4)
  String? instanceId;

  @HiveField(5)
  String? ipName;

  @HiveField(6)
  String? sector;

  @HiveField(7)
  String? indicator;

  @HiveField(8)
  String? date; // Date stored as ISO string

  @HiveField(9)
  String? name;

  @HiveField(10)
  String? idNumber;

  @HiveField(11)
  String? parentId;

  @HiveField(12)
  String? spouseId;

  @HiveField(13)
  String? phoneNumber;

  @HiveField(14)
  String? dateOfBirth;

  @HiveField(15)
  String? age;

  @HiveField(16)
  String? gender;

  @HiveField(17)
  String? governorate;

  @HiveField(18)
  String? municipality;

  @HiveField(19)
  String? neighborhood;

  @HiveField(20)
  String? siteName;

  @HiveField(21)
  String? disabilityStatus;

  // Timestamps
  @HiveField(22)
  String? updatedAt;

  @HiveField(23)
  String? createdAt;

  @HiveField(24)
  String? submissionTime;

  // Created by
  @HiveField(25)
  String? createdBy;

  // Soft delete fields
  @HiveField(26)
  bool? deleted = false;

  @HiveField(27)
  String? deletedAt;

  @HiveField(28)
  String? deletedBy;

  @HiveField(29)
  String? undeletedAt;

  @HiveField(30)
  String? undeletedBy;

  // Household
  @HiveField(31)
  String? householdId;

  // Sync status
  @HiveField(32)
  String? synced;

  @HiveField(33)
  String? updatedBy;

  // ---------------------------
  // CONSTRUCTOR
  // ---------------------------

  Beneficiary({
    this.id,
    this.localId,
    this.recordId,
    this.inFormId,
    this.instanceId,
    this.ipName,
    this.sector,
    this.indicator,
    this.date,
    this.name,
    this.idNumber,
    this.parentId,
    this.spouseId,
    this.phoneNumber,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.governorate,
    this.municipality,
    this.neighborhood,
    this.siteName,
    this.disabilityStatus,
    this.updatedAt,
    this.createdAt,
    this.submissionTime,
    this.createdBy,
    this.deleted = false,
    this.deletedAt,
    this.deletedBy,
    this.undeletedAt,
    this.undeletedBy,
    this.householdId,
    this.synced,
    this.updatedBy,
  }) {
    if (localId != null) this.localId = localId;
  }

  // ---------------------------
  // SAFE HELPERS
  // ---------------------------

  static String? _toStr(dynamic v) => v?.toString();

  static bool? _toBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == "true";
    return null;
  }

  // ---------------------------
  // FROM JSON
  // ---------------------------

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json["id"],
      recordId: _toStr(json["record_id"]),
      inFormId: _toStr(json["InForm_ID"]),
      instanceId: _toStr(json["InstanceID"]),
      ipName: _toStr(json["IP_Name"]),
      sector: _toStr(json["Sector"]),
      indicator: _toStr(json["Indicator"]),
      date: _toStr(json["Date"]),
      name: _toStr(json["Name"]),
      idNumber: _toStr(json["ID_Number"]),
      parentId: _toStr(json["Parent_ID"]),
      spouseId: _toStr(json["Spouse_ID"]),
      phoneNumber: _toStr(json["Phone_Number"]),
      dateOfBirth: _toStr(json["Date_of_Birth"]),
      age: _toStr(json["Age"]),
      gender: _toStr(json["Gender"]),
      governorate: _toStr(json["Governorate"]),
      municipality: _toStr(json["Municipality"]),
      neighborhood: _toStr(json["Neighborhood"]),
      siteName: _toStr(json["Site_Name"]),
      disabilityStatus: _toStr(json["Disability_Status"]),
      updatedAt: _toStr(json["updated_at"]),
      createdAt: _toStr(json["created_at"]),
      submissionTime: _toStr(json["Submission_Time"]),
      createdBy: _toStr(json["created_by"]),
      deleted: _toBool(json["Deleted"]) ?? false,
      deletedAt: _toStr(json["deleted_at"]),
      deletedBy: _toStr(json["deleted_by"]),
      undeletedAt: _toStr(json["undeleted_at"]),
      undeletedBy: _toStr(json["undeleted_by"]),
      householdId: _toStr(json["Household_ID"]),
      synced: _toStr(json["synced"]),
      updatedBy: json["updated_by"],
    );
  }

  // ---------------------------
  // TO JSON
  // ---------------------------

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "localId": localId,
      "record_id": recordId,
      "InForm_ID": inFormId,
      "InstanceID": instanceId,
      "IP_Name": ipName,
      "Sector": sector,
      "Indicator": indicator,
      "Date": date,
      "Name": name,
      "ID_Number": idNumber,
      "Parent_ID": parentId,
      "Spouse_ID": spouseId,
      "Phone_Number": phoneNumber,
      "Date_of_Birth": dateOfBirth,
      "Age": age,
      "Gender": gender,
      "Governorate": governorate,
      "Municipality": municipality,
      "Neighborhood": neighborhood,
      "Site_Name": siteName,
      "Disability_Status": disabilityStatus,
      "updated_at": updatedAt,
      "created_at": createdAt,
      "Submission_Time": submissionTime,
      "created_by": createdBy,
      "Deleted": deleted,
      "deleted_at": deletedAt,
      "deleted_by": deletedBy,
      "undeleted_at": undeletedAt,
      "undeleted_by": undeletedBy,
      "Household_ID": householdId,
      "synced": synced,
      "updated_by": updatedBy,
    };
  }
}
