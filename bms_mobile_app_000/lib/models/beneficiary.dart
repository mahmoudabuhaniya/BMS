import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'beneficiary.g.dart';

@HiveType(typeId: 1)
class Beneficiary extends HiveObject {
  // IMPORTANT: id must be INT
  @HiveField(29)
  int? id;

  @HiveField(0)
  String uuid;

  @HiveField(1)
  String? recordId;

  @HiveField(2)
  String? inFormId;

  @HiveField(3)
  String? instanceId;

  @HiveField(4)
  String? ipName;

  @HiveField(5)
  String? sector;

  @HiveField(6)
  String? indicator;

  @HiveField(7)
  String? date;

  @HiveField(8)
  String? name;

  @HiveField(9)
  String? idNumber;

  @HiveField(10)
  String? parentId;

  @HiveField(11)
  String? spouseId;

  @HiveField(12)
  String? phoneNumber;

  @HiveField(13)
  String? dateOfBirth;

  @HiveField(14)
  String? age;

  @HiveField(15)
  String? gender;

  @HiveField(16)
  String? governorate;

  @HiveField(17)
  String? municipality;

  @HiveField(18)
  String? neighborhood;

  @HiveField(19)
  String? siteName;

  @HiveField(20)
  String? disabilityStatus;

  @HiveField(21)
  String? submissionTime;

  @HiveField(22)
  String? householdId;

  @HiveField(23)
  bool deleted;

  @HiveField(24)
  String? deletedAt;

  @HiveField(25)
  String? undeletedAt;

  @HiveField(26)
  String? createdBy;

  @HiveField(27)
  String? createdAt;

  @HiveField(28)
  String? synced;

  Beneficiary({
    this.id,
    String? uuid,
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
    this.householdId,
    this.deleted = false,
    this.deletedAt,
    this.undeletedAt,
    this.createdBy,
    this.createdAt,
    this.synced = "no",
  }) : uuid = uuid ?? const Uuid().v4();

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json["id"], // FIX: keep integer
      uuid: json["uuid"] ?? const Uuid().v4(),

      recordId: json["record_id"],
      inFormId: json["in_form_id"] ?? json["InForm_ID"],
      instanceId: json["instance_id"] ?? json["InstanceID"],

      ipName: json["IP_Name"],
      sector: json["Sector"],
      indicator: json["Indicator"],
      date: json["Date"],
      name: json["Name"],
      idNumber: json["ID_Number"],
      parentId: json["Parent_ID"],
      spouseId: json["Spouse_ID"],
      phoneNumber: json["Phone_Number"],

      dateOfBirth: json["Date_of_Birth"],
      age: json["Age"]?.toString(),
      gender: json["Gender"],
      governorate: json["Governorate"],
      municipality: json["Municipality"],
      neighborhood: json["Neighborhood"],
      siteName: json["Site_Name"],
      disabilityStatus: json["Disability_Status"],
      submissionTime: json["Submission_Time"],

      householdId: json["Household_ID"],
      deleted: json["Deleted"] ?? false,

      deletedAt: json["deleted_at"],
      undeletedAt: json["undeleted_at"],
      createdBy: json["created_by"],
      createdAt: json["created_at"],

      synced: json["synced"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "uuid": uuid,
      "record_id": recordId,
      "in_form_id": inFormId,
      "instance_id": instanceId,
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
      "Household_ID": householdId,
      "Deleted": deleted,
      "deleted_at": deletedAt,
      "undeleted_at": undeletedAt,
      "created_by": createdBy,
      "created_at": createdAt,
      "synced": synced,
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
