import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'theme.dart';
import 'models/beneficiary.dart';
import 'services/token_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(BeneficiaryAdapter());

  await Hive.openBox('beneficiaries');
  await Hive.openBox('pending_queue');
  await Hive.openBox('dropdown_cache');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "BMS Offline App",
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
