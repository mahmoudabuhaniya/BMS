import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'db/hive_manager.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveManager.initHive();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, SyncService>(
          create: (_) => SyncService(),
          update: (_, auth, sync) {
            sync ??= SyncService();
            sync.attachAuth(auth);
            return sync;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final sync = Provider.of<SyncService>(context, listen: false);
    sync.startAutoSync();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
