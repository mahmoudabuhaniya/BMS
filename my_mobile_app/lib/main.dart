import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/beneficiary.dart';
import 'offline/beneficiary_repository.dart';
import 'offline/pending_queue.dart';
import 'offline/sync_service.dart';
import 'services/token_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ---------------------------
  // 1. Init Hive
  // ---------------------------
  await Hive.initFlutter();

  Hive.registerAdapter(BeneficiaryAdapter());

  await BeneficiaryRepository.init();
  await PendingQueue.init();

  // ---------------------------
  // 2. Try to restore tokens
  // ---------------------------
  final token = await TokenService.getAccessToken();
  final refresh = await TokenService.getRefreshToken();

  bool loggedIn = false;

  if (token != null && refresh != null) {
    // ---------------------------
    // 3. Attempt token refresh (auto-login)
    // ---------------------------
    try {
      await TokenService.refreshTokensIfNeeded();
      loggedIn = true;
    } catch (_) {
      loggedIn = false;
    }
  }

  // ---------------------------
  // 4. Start background sync
  // ---------------------------
  if (loggedIn) {
    await SyncService.processQueue();
  }

  // ---------------------------
  // 5. Launch the app
  // ---------------------------
  runApp(BMSApp(loggedIn: loggedIn));
}

class BMSApp extends StatelessWidget {
  final bool loggedIn;
  const BMSApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "BMS Offline App",
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: loggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
