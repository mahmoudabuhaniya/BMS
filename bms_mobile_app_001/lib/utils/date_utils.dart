import 'package:intl/intl.dart';

class DateUtilsHelper {
  static final DateFormat _fmt = DateFormat("yyyy-MM-dd");

  // ----------------------------------------
  // Parse yyyy-MM-dd safely
  // ----------------------------------------
  static DateTime? parse(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  // ----------------------------------------
  // Format DateTime to yyyy-MM-dd
  // ----------------------------------------
  static String? format(DateTime? date) {
    if (date == null) return null;
    return _fmt.format(date);
  }

  // ----------------------------------------
  // Normalize input (empty -> null)
  // ----------------------------------------
  static String? normalizeInput(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      DateTime dt = DateTime.parse(value);
      return _fmt.format(dt);
    } catch (_) {
      return null; // invalid date ignored
    }
  }
}
