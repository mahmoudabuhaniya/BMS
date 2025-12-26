class Beneficiary {
  final int? id;

  final String? recordId;
  final String? inFormId;
  final String? instanceId;
  final String? ipName;
  final String? sector;
  final String? indicator;
  final String? date;
  final String? name;
  final String? idNumber;
  final String? parentId;
  final String? spouseId;
  final String? phoneNumber;
  final String? dateOfBirth;
  final String? age;
  final String? gender;
  final String? governorate;
  final String? municipality;
  final String? neighborhood;
  final String? siteName;
  final String? disabilityStatus;
  final String? createdAt;
  final String? createdBy;
  final String? submissionTime;
  final bool deleted;
  final String? deletedAt;
  final String? undeletedAt;
  final String? householdId;
  final String? synced;

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
    this.createdAt,
    this.createdBy,
    this.submissionTime,
    this.deleted = false,
    this.deletedAt,
    this.undeletedAt,
    this.householdId,
    this.synced,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json['id'] as int?,
      recordId: json['record_id']?.toString(),
      inFormId: json['InForm_ID']?.toString(),
      instanceId: json['InstanceID']?.toString(),
      ipName: json['IP_Name']?.toString(),
      sector: json['Sector']?.toString(),
      indicator: json['Indicator']?.toString(),
      date: json['Date']?.toString(),
      name: json['Name']?.toString(),
      idNumber: json['ID_Number']?.toString(),
      parentId: json['Parent_ID']?.toString(),
      spouseId: json['Spouse_ID']?.toString(),
      phoneNumber: json['Phone_Number']?.toString(),
      dateOfBirth: json['Date_of_Birth']?.toString(),
      age: json['Age']?.toString(),
      gender: json['Gender']?.toString(),
      governorate: json['Governorate']?.toString(),
      municipality: json['Municipality']?.toString(),
      neighborhood: json['Neighborhood']?.toString(),
      siteName: json['Site_Name']?.toString(),
      disabilityStatus: json['Disability_Status']?.toString(),
      createdAt: json['created_at']?.toString(),
      createdBy: json['created_by_username']?.toString() ??
          json['created_by']?.toString(),
      submissionTime: json['Submission_Time']?.toString(),
      deleted: (json['Deleted'] ?? false) == true,
      deletedAt: json['deleted_at']?.toString(),
      undeletedAt: json['undeleted_at']?.toString(),
      householdId: json['Household_ID']?.toString(),
      synced: json['synced']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'record_id': recordId,
      'InForm_ID': inFormId,
      'InstanceID': instanceId,
      'IP_Name': ipName,
      'Sector': sector,
      'Indicator': indicator,
      'Date': date,
      'Name': name,
      'ID_Number': idNumber,
      'Parent_ID': parentId,
      'Spouse_ID': spouseId,
      'Phone_Number': phoneNumber,
      'Date_of_Birth': dateOfBirth,
      'Age': age,
      'Gender': gender,
      'Governorate': governorate,
      'Municipality': municipality,
      'Neighborhood': neighborhood,
      'Site_Name': siteName,
      'Disability_Status': disabilityStatus,
      'created_at': createdAt,
      'created_by': createdBy,
      'Submission_Time': submissionTime,
      'Deleted': deleted,
      'deleted_at': deletedAt,
      'undeleted_at': undeletedAt,
      'Household_ID': householdId,
      'synced': synced,
    };
  }

  Beneficiary copyWith({
    int? id,
    String? ipName,
    String? sector,
    String? name,
    String? idNumber,
    String? indicator,
    String? date,
    String? parentId,
    String? spouseId,
    String? phoneNumber,
    String? dateOfBirth,
    String? age,
    String? gender,
    String? governorate,
    String? municipality,
    String? neighborhood,
    String? siteName,
    String? disabilityStatus,
    String? submissionTime,
    bool? deleted,
    String? synced,
  }) {
    return Beneficiary(
      id: id ?? this.id,
      recordId: recordId,
      inFormId: inFormId,
      instanceId: instanceId,
      ipName: ipName ?? this.ipName,
      sector: sector ?? this.sector,
      indicator: indicator ?? this.indicator,
      date: date ?? this.date,
      name: name ?? this.name,
      idNumber: idNumber ?? this.idNumber,
      parentId: parentId ?? this.parentId,
      spouseId: spouseId ?? this.spouseId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      governorate: governorate ?? this.governorate,
      municipality: municipality ?? this.municipality,
      neighborhood: neighborhood ?? this.neighborhood,
      siteName: siteName ?? this.siteName,
      disabilityStatus: disabilityStatus ?? this.disabilityStatus,
      createdAt: createdAt,
      createdBy: createdBy,
      submissionTime: submissionTime ?? this.submissionTime,
      deleted: deleted ?? this.deleted,
      deletedAt: deletedAt,
      undeletedAt: undeletedAt,
      householdId: householdId,
      synced: synced ?? this.synced,
    );
  }
}
