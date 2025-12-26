import 'package:hive/hive.dart';

part 'beneficiary.g.dart';

@HiveType(typeId: 1)
class Beneficiary {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final String uuid; // local identifier

  @HiveField(2)
  final String? recordId;

  @HiveField(3)
  final String? inFormId;

  @HiveField(4)
  final String? ipName;

  @HiveField(5)
  final String? sector;

  @HiveField(6)
  final String? indicator;

  @HiveField(7)
  final String? date;

  @HiveField(8)
  final String? name;

  @HiveField(9)
  final String? idNumber;

  @HiveField(10)
  final String? phoneNumber;

  @HiveField(11)
  final String? dateOfBirth;

  @HiveField(12)
  final int? age;

  @HiveField(13)
  final String? gender;

  @HiveField(14)
  final String? governorate;

  @HiveField(15)
  final String? municipality;

  @HiveField(16)
  final String? neighborhood;

  @HiveField(17)
  final String? siteName;

  @HiveField(18)
  final bool? disabilityStatus;

  @HiveField(19)
  final bool deleted;

  @HiveField(20)
  final String? createdBy;

  @HiveField(21)
  final String? submissionTime;

  @HiveField(22)
  final String synced;
  // "yes", "no", "update", "delete"

  Beneficiary({
    this.id,
    required this.uuid,
    this.recordId,
    this.inFormId,
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
    this.deleted = false,
    this.createdBy,
    this.submissionTime,
    this.synced = "yes",
  });

  // ----------------------------------------------------------
  // FROM JSON (Backend → App)
  // ----------------------------------------------------------
  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json["id"],
      uuid: json["uuid"] ?? "", // backend may not return uuid
      recordId: json["recordId"],
      inFormId: json["inFormId"],
      ipName: json["ipName"],
      sector: json["sector"],
      indicator: json["indicator"],
      date: json["date"],
      name: json["name"],
      idNumber: json["idNumber"],
      phoneNumber: json["phoneNumber"],
      dateOfBirth: json["dateOfBirth"],
      age: json["age"],
      gender: json["gender"],
      governorate: json["governorate"],
      municipality: json["municipality"],
      neighborhood: json["neighborhood"],
      siteName: json["siteName"],
      disabilityStatus: json["disabilityStatus"],
      deleted: json["deleted"] ?? false,
      createdBy: json["created_by"],
      submissionTime: json["submission_time"],
      synced: "yes",
    );
  }

  // ----------------------------------------------------------
  // TO JSON (App → API)
  // ----------------------------------------------------------
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "uuid": uuid,
      "recordId": recordId,
      "inFormId": inFormId,
      "ipName": ipName,
      "sector": sector,
      "indicator": indicator,
      "date": date,
      "name": name,
      "idNumber": idNumber,
      "phoneNumber": phoneNumber,
      "dateOfBirth": dateOfBirth,
      "age": age,
      "gender": gender,
      "governorate": governorate,
      "municipality": municipality,
      "neighborhood": neighborhood,
      "siteName": siteName,
      "disabilityStatus": disabilityStatus,
      "deleted": deleted,
      "created_by": createdBy,
      "submission_time": submissionTime,
    };
  }

  // ----------------------------------------------------------
  // COPY WITH (used for updates)
  // ----------------------------------------------------------
  Beneficiary copyWith({
    int? id,
    String? uuid,
    String? recordId,
    String? inFormId,
    String? ipName,
    String? sector,
    String? indicator,
    String? date,
    String? name,
    String? idNumber,
    String? phoneNumber,
    String? dateOfBirth,
    int? age,
    String? gender,
    String? governorate,
    String? municipality,
    String? neighborhood,
    String? siteName,
    bool? disabilityStatus,
    bool? deleted,
    String? createdBy,
    String? submissionTime,
    String? synced,
  }) {
    return Beneficiary(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      recordId: recordId ?? this.recordId,
      inFormId: inFormId ?? this.inFormId,
      ipName: ipName ?? this.ipName,
      sector: sector ?? this.sector,
      indicator: indicator ?? this.indicator,
      date: date ?? this.date,
      name: name ?? this.name,
      idNumber: idNumber ?? this.idNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      governorate: governorate ?? this.governorate,
      municipality: municipality ?? this.municipality,
      neighborhood: neighborhood ?? this.neighborhood,
      siteName: siteName ?? this.siteName,
      disabilityStatus: disabilityStatus ?? this.disabilityStatus,
      deleted: deleted ?? this.deleted,
      createdBy: createdBy ?? this.createdBy,
      submissionTime: submissionTime ?? this.submissionTime,
      synced: synced ?? this.synced,
    );
  }
}
