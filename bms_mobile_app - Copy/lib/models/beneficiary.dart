import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'beneficiary.g.dart';

@HiveType(typeId: 1)
class Beneficiary extends HiveObject {
  // Local UUID (never sent to backend)
  @HiveField(0)
  String uuid;

  // SERVER FIELDS
  @HiveField(1)
  int? id;

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
  String? date; // yyyy-MM-dd

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
  int? age;

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

  @HiveField(22)
  String? submissionTime;

  @HiveField(23)
  bool deleted;

  @HiveField(24)
  String? householdId;

  /// synced = "yes" | "no" | "update" | "delete"
  @HiveField(25)
  String synced;

  @HiveField(26)
  String? createdBy;

  Beneficiary({
    this.id,
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
    this.submissionTime,
    this.deleted = false,
    this.householdId,
    this.createdBy,
    this.synced = "no",
  }) : uuid = const Uuid().v4();

  // ---------------------------
  // FROM API JSON
  // ---------------------------
  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json['id'],
      recordId: json['record_id'],
      inFormId: json['InForm_ID'],
      instanceId: json['InstanceID'],
      ipName: json['IP_Name'],
      sector: json['Sector'],
      indicator: json['Indicator'],
      date: json['Date'],
      name: json['Name'],
      idNumber: json['ID_Number'],
      parentId: json['Parent_ID'],
      spouseId: json['Spouse_ID'],
      phoneNumber: json['Phone_Number'],
      dateOfBirth: json['Date_of_Birth'],
      age: json['Age'] == null ? null : int.tryParse(json['Age'].toString()),
      gender: json['Gender'],
      governorate: json['Governorate'],
      municipality: json['Municipality'],
      neighborhood: json['Neighborhood'],
      siteName: json['Site_Name'],
      disabilityStatus: json['Disability_Status'],
      submissionTime: json['Submission_Time'],
      deleted: json['Deleted'] ?? false,
      householdId: json['Household_ID'],
      createdBy: json['created_by'],
      synced: "yes", // anything from API is considered synced
    );
  }

  // ---------------------------
  // TO API JSON (create/update)
  // ---------------------------
  Map<String, dynamic> toJson() {
    return {
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
      "Submission_Time": submissionTime,
      "Deleted": deleted,
      "Household_ID": householdId,
      "created_by": createdBy,
    };
  }

  // ---------------------------
  // HIVE STORAGE MAP
  // ---------------------------
  Map<String, dynamic> toMap() => toJson();

  factory Beneficiary.fromMap(Map<String, dynamic> map) {
    return Beneficiary.fromJson(map);
  }
}
