import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'db/hive_manager.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  // -------------------------------------------------------
  // 1️⃣ Initialize Hive (open all boxes + register adapters)
  // -------------------------------------------------------
  await HiveManager.init();
  await Hive.openBox('meta');
  print("🕒 LAST SYNC: ${HiveManager.getLastSyncTime()}");

  // -------------------------------------------------------
  // 2️⃣ Initialize AuthService & Load Saved Session
  // -------------------------------------------------------
  final auth = AuthService();
  await auth.loadSavedUser(); // loads tokens + profile from Hive

  // -------------------------------------------------------
  // 3️⃣ Initialize SyncService AFTER Auth is Loaded
  // -------------------------------------------------------
  final sync = SyncService();
  sync.attachAuth(auth);
  if (auth.isLoggedIn) {
    await sync.initialize();
  }

  // -------------------------------------------------------
  // 4️⃣ Run App
  // -------------------------------------------------------
  runApp(BMSApp(auth: auth, sync: sync));
}

class BMSApp extends StatelessWidget {
  final AuthService auth;
  final SyncService sync;

  const BMSApp({super.key, required this.auth, required this.sync});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<SyncService>.value(value: sync),
      ],
      child: MaterialApp(
        title: "Beneficiary Management System",
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        // Automatically choose /login or /home
        initialRoute: AppRouter.initialRoute(auth),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
