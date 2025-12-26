class Helpers {
  // ----------------------------------------
  // Convert '' → null
  // ----------------------------------------
  static String? emptyToNull(String? value) {
    if (value == null) return null;
    if (value.trim().isEmpty) return null;
    return value;
  }

  // ----------------------------------------
  // Convert null → '' (for text fields)
  // ----------------------------------------
  static String nullToEmpty(String? value) {
    return value ?? "";
  }

  // ----------------------------------------
  // Safe map getter
  // ----------------------------------------
  static T? get<T>(Map data, String key) {
    if (!data.containsKey(key)) return null;
    final value = data[key];
    if (value is T) return value;
    return null;
  }

  // ----------------------------------------
  // Build full name (first + last)
  // ----------------------------------------
  static String fullName(String? first, String? last) {
    return "${first ?? ""} ${last ?? ""}".trim();
  }

  // ----------------------------------------
  // Age calculation from DOB
  // ----------------------------------------
  static int? calculateAge(DateTime? dob) {
    if (dob == null) return null;

    final today = DateTime.now();
    int age = today.year - dob.year;

    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }

    return age;
  }
}
