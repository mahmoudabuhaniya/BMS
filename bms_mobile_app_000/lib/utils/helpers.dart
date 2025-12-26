class Helpers {
  static String nullToEmpty(String? v) => v ?? "";
  static String? emptyToNull(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  static int? calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    return now.year -
        dob.year -
        (now.month < dob.month || (now.month == dob.month && now.day < dob.day)
            ? 1
            : 0);
  }
}
