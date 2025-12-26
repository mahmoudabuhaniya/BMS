import 'package:flutter/material.dart';
import '../db/hive_manager.dart';
import '../models/beneficiary.dart';

class DeletedBeneficiaryListScreen extends StatelessWidget {
  const DeletedBeneficiaryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deleted = HiveManager.beneficiaries.values
        .where((b) => b.deleted == true)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Deleted Beneficiaries")),
      body: ListView.builder(
        itemCount: deleted.length,
        itemBuilder: (_, i) {
          final b = deleted[i];
          return ListTile(
            title: Text(b.name ?? "No Name"),
            subtitle: Text(b.idNumber ?? ""),
          );
        },
      ),
    );
  }
}
