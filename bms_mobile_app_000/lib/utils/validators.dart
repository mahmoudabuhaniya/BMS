class Validators {
  static String? required(String? v) {
    if (v == null || v.trim().isEmpty) return "Required field";
    return null;
  }

  static String? idNumber(String? v) {
    if (v == null || v.trim().isEmpty) return "Required field";
    if (v.length < 6) return "Invalid ID number";
    return null;
  }
}
