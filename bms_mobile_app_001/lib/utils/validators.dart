class Validators {
  // ----------------------------------------
  // Required Field Validator
  // ----------------------------------------
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "This field is required";
    }
    return null;
  }

  // ----------------------------------------
  // Numeric Validator
  // ----------------------------------------
  static String? numeric(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return "Numbers only";
    }
    return null;
  }

  // ----------------------------------------
  // Email Validator
  // ----------------------------------------
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
      return "Invalid email";
    }
    return null;
  }

  // ----------------------------------------
  // ID Number Validator (Optional)
  // ----------------------------------------
  static String? idNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "ID Number is required";
    }
    if (!RegExp(r'^[0-9A-Za-z\-]+$').hasMatch(value)) {
      return "Invalid characters in ID";
    }
    return null;
  }
}
