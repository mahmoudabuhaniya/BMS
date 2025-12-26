import 'package:intl/intl.dart';

class DateUtilsHelper {
  static DateTime? parse(String? v) {
    if (v == null || v.isEmpty) return null;
    try {
      return DateFormat("yyyy-MM-dd").parse(v);
    } catch (_) {
      return null;
    }
  }
}
