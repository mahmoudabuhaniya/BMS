import 'package:flutter/material.dart';
import 'offline/storage/hive_initializer.dart';
import 'offline/sync/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInitializer.init();
  // Start auto-sync (listens to connectivity changes)
  SyncService.startAutoSync();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline First Template',
      home: Scaffold(
        appBar: AppBar(title: const Text('Offline-first Template')),
        body: const Center(
            child: Text('Integrate into your app by copying files.')),
      ),
    );
  }
}
