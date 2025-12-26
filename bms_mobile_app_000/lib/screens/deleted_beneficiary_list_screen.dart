import 'package:flutter/material.dart';

import '../db/hive_manager.dart';
import '../models/beneficiary.dart';
import '../widgets/sync_status_cloud.dart';
import '../theme/app_theme.dart';

class DeletedBeneficiaryListScreen extends StatefulWidget {
  const DeletedBeneficiaryListScreen({super.key});

  @override
  State<DeletedBeneficiaryListScreen> createState() =>
      _DeletedBeneficiaryListScreenState();
}

class _DeletedBeneficiaryListScreenState
    extends State<DeletedBeneficiaryListScreen> {
  List<Beneficiary> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final box = HiveManager.beneficiariesBox;
    final raw = box.values.where((b) => b.deleted == true).toList();

    // FIXED SORT
    raw.sort((a, b) {
      final aDate = DateTime.tryParse(a.deletedAt ?? "") ?? DateTime(2000);
      final bDate = DateTime.tryParse(b.deletedAt ?? "") ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    setState(() => items = raw);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deleted Records"),
        backgroundColor: AppTheme.unicefBlue,
      ),
      body: items.isEmpty
          ? const Center(child: Text("No deleted records"))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (_, i) {
                final b = items[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(b.name ?? "No Name"),
                    subtitle: Text("Deleted at: ${b.deletedAt}"),
                    trailing: SyncStatusCloud(status: b.synced ?? "pending"),
                  ),
                );
              },
            ),
    );
  }
}
