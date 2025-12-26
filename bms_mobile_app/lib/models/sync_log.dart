import 'package:hive/hive.dart';

part 'sync_log.g.dart';

@HiveType(typeId: 3)
class SyncLog extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final String message;

  @HiveField(2)
  final bool success;

  SyncLog({
    required this.timestamp,
    required this.message,
    required this.success,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'message': message,
        'success': success,
      };

  factory SyncLog.fromJson(Map<String, dynamic> json) => SyncLog(
        timestamp: DateTime.parse(json['timestamp']),
        message: json['message'],
        success: json['success'],
      );
}
