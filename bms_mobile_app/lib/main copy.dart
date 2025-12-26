import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'db/hive_manager.dart';
import 'routing/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Open all Hive boxes
  await HiveManager.init();

  // 2️⃣ Auth
  final auth = AuthService();
  await auth.loadSavedUser();

  // 3️⃣ Sync service
  final sync = SyncService();
  sync.attachAuth(auth);
  await sync.initialize(); // ⭐ IMPORTANT ⭐

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
          scaffoldBackgroundColor: Colors.grey.shade100,
        ),
        initialRoute: AppRouter.initialRoute(auth),
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
