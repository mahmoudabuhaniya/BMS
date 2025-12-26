import 'dart:convert';

class Beneficiary {
  final String uuid; // Unique local ID
  String? recordId;
  String? inFormId;
  String? instanceId;

  String? name;
  String? idNumber;
  String? ipName;
  String? sector;

  String? indicator;
  String? date;

  String? phoneNumber;
  String? dateOfBirth;
  int? age;
  String? gender;

  String? governorate;
  String? municipality;
  String? neighborhood;
  String? siteName;

  String? disabilityStatus;
  String? submissionTime;

  bool deleted; // For soft delete
  bool synced; // To track sync status

  Beneficiary({
    required this.uuid,
    this.recordId,
    this.inFormId,
    this.instanceId,
    this.name,
    this.idNumber,
    this.ipName,
    this.sector,
    this.indicator,
    this.date,
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
    this.synced = false,
  });

  // ------------------------------
  // JSON → MODEL
  // ------------------------------
  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      uuid: json["uuid"] ?? "",
      recordId: json["recordId"],
      inFormId: json["inFormId"],
      instanceId: json["instanceId"],
      name: json["name"],
      idNumber: json["idNumber"],
      ipName: json["ipName"],
      sector: json["sector"],
      indicator: json["indicator"],
      date: json["date"],
      phoneNumber: json["phoneNumber"],
      dateOfBirth: json["dateOfBirth"],
      age: json["age"],
      gender: json["gender"],
      governorate: json["governorate"],
      municipality: json["municipality"],
      neighborhood: json["neighborhood"],
      siteName: json["siteName"],
      disabilityStatus: json["disabilityStatus"],
      submissionTime: json["submissionTime"],
      deleted: json["deleted"] ?? false,
      synced: json["synced"] ?? false,
    );
  }

  // ------------------------------
  // MODEL → JSON
  // ------------------------------
  Map<String, dynamic> toJson() {
    return {
      "uuid": uuid,
      "recordId": recordId,
      "inFormId": inFormId,
      "instanceId": instanceId,
      "name": name,
      "idNumber": idNumber,
      "ipName": ipName,
      "sector": sector,
      "indicator": indicator,
      "date": date,
      "phoneNumber": phoneNumber,
      "dateOfBirth": dateOfBirth,
      "age": age,
      "gender": gender,
      "governorate": governorate,
      "municipality": municipality,
      "neighborhood": neighborhood,
      "siteName": siteName,
      "disabilityStatus": disabilityStatus,
      "submissionTime": submissionTime,
      "deleted": deleted,
      "synced": synced,
    };
  }

  // ------------------------------
  // MAP → MODEL  (offline use)
  // ------------------------------
  factory Beneficiary.fromMap(Map<String, dynamic> map) {
    return Beneficiary.fromJson(map);
  }

  // ------------------------------
  // MODEL → MAP (offline / Hive)
  // ------------------------------
  Map<String, dynamic> toMap() => toJson();

  // ------------------------------
  // UPDATE LOCAL COPY AFTER SERVER SYNC
  // ------------------------------
  void applyServerSync(Map<String, dynamic> server) {
    recordId = server["recordId"] ?? recordId;
    inFormId = server["inFormId"] ?? inFormId;
    instanceId = server["instanceId"] ?? instanceId;
    synced = true;
  }
}
