import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'beneficiary.g.dart';

@HiveType(typeId: 1)
class Beneficiary extends HiveObject {
  // -------------------------------------------------------------
  // PRIMARY KEYS
  // -------------------------------------------------------------

  // Django DB ID (Main key for synced records)
  @HiveField(0)
  int? id;

  // Local unique ID (Used before sync)
  @HiveField(1)
  String localId;

  // -------------------------------------------------------------
  // FIELDS
  // -------------------------------------------------------------
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
  String? date;

  @HiveField(9)
  String? name;

  @HiveField(10)
  String? idNumber;

  @HiveField(11)
  String? phoneNumber;

  @HiveField(12)
  String? dateOfBirth;

  @HiveField(13)
  String? age;

  @HiveField(14)
  String? gender;

  @HiveField(15)
  String? governorate;

  @HiveField(16)
  String? municipality;

  @HiveField(17)
  String? neighborhood;

  @HiveField(18)
  String? siteName;

  @HiveField(19)
  String? disabilityStatus;

  @HiveField(20)
  String? submissionTime;

  @HiveField(21)
  bool? deleted;

  @HiveField(22)
  String synced; // yes / no

  @HiveField(23)
  String? parentId;

  @HiveField(24)
  String? spouseId;

  @HiveField(25)
  String? createdBy;

  // -------------------------------------------------------------
  // CONSTRUCTOR
  // -------------------------------------------------------------
  Beneficiary({
    this.id, // null if local-only
    String? localId,
    this.recordId,
    this.inFormId,
    this.instanceId,
    this.ipName,
    this.sector,
    this.indicator,
    this.date,
    this.name,
    this.idNumber,
    this.phoneNumber,
    this.dateOfBirth,
    this.age,
    this.gender,
    this.governorate,
    this.municipality,
    this.neighborhood,
    this.siteName,
    this.disabilityStatus,
    this.submissionTime,
    this.deleted = false,
    this.synced = "no",
    this.parentId,
    this.spouseId,
    this.createdBy,
  }) : localId = localId ?? const Uuid().v4();

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String && v.trim().isEmpty) return null;
    return int.tryParse(v.toString());
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == "true";
    return false;
  }

  // -------------------------------------------------------------
  // FACTORY (FROM SERVER)
  // -------------------------------------------------------------
  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: _toInt(json["id"]), // PRIMARY KEY
      localId: json["localId"] ?? const Uuid().v4(), // Create if missing
      recordId: json["record_id"],
      inFormId: json["InForm_ID"],
      instanceId: json["InstanceID"],
      ipName: json["IP_Name"],
      sector: json["Sector"],
      indicator: json["Indicator"],
      date: json["Date"],
      name: json["Name"],
      idNumber: json["ID_Number"],
      phoneNumber: json["Phone_Number"],
      dateOfBirth: json["Date_of_Birth"],
      age: json["Age"],
      gender: json["Gender"],
      governorate: json["Governorate"],
      municipality: json["Municipality"],
      neighborhood: json["Neighborhood"],
      siteName: json["Site_Name"],
      disabilityStatus: json["Disability_Status"],
      submissionTime: json["Submission_Time"],
      deleted: (json["Deleted"] == true),
      synced: json["synced"] ?? "yes", // server → synced
      parentId: json["Parent_ID"],
      spouseId: json["Spouse_ID"],
      createdBy: json["created_by"],
    );
  }

  // -------------------------------------------------------------
  // TO JSON
  // -------------------------------------------------------------
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
      "Phone_Number": phoneNumber,
      "Date_of_Birth": dateOfBirth,
      "Age": age,
      "Gender": gender,
      "Governorate": governorate,
      "Municipality": municipality,
      "Neighborhood": neighborhood,
      "Site_Name": siteName,
      "Disability_Status": disabilityStatus,
      "Submission_Time": submissionTime,
      "Deleted": deleted,
      "synced": synced,
      "Parent_ID": parentId,
      "Spouse_ID": spouseId,
      "created_by": createdBy,
    };
  }
}
