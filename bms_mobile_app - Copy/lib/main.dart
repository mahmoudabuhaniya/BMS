import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'db/hive_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local DB
  await HiveManager.initHive();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => SyncService()),
      ],
      child: const MyApp(),
    ),
  );
}
