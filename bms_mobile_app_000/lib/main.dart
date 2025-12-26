import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'db/hive_manager.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveManager.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),

        // ⭐ FIXED: Proxy provider that updates SyncService when Auth changes
        ChangeNotifierProxyProvider<AuthService, SyncService>(
          create: (_) => SyncService(null),
          update: (_, auth, previous) {
            previous?.updateAuth(auth);
            return previous ?? SyncService(auth);
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}
