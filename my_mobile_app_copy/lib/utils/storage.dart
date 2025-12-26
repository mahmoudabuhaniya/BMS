import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final storage = FlutterSecureStorage();

Future<void> saveTokens({required String access, required String refresh}) async {
  await storage.write(key: 'accessToken', value: access);
  await storage.write(key: 'refreshToken', value: refresh);
}

Future<String?> getAccessToken() async => await storage.read(key: 'accessToken');
Future<String?> getRefreshToken() async => await storage.read(key: 'refreshToken');

Future<void> clearTokens() async {
  await storage.deleteAll();
}
