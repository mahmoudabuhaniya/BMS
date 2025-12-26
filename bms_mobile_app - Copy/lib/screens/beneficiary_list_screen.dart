import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../db/hive_manager.dart';
import '../models/beneficiary.dart';
import '../services/sync_service.dart';
import 'beneficiary_detail_screen.dart';

class BeneficiaryListScreen extends StatefulWidget {
  const BeneficiaryListScreen({super.key});

  @override
  State<BeneficiaryListScreen> createState() => _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends State<BeneficiaryListScreen> {
  String search = "";

  @override
  Widget build(BuildContext context) {
    final sync = Provider.of<SyncService>(context);
    final all = HiveManager.beneficiaries.values.toList();

    final filtered = all.where((b) {
      if (search.isEmpty) return true;
      return (b.name ?? "").toLowerCase().contains(search.toLowerCase()) ||
          (b.idNumber ?? "").contains(search);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Beneficiaries"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.search),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                labelText: "Search by name or ID",
              ),
              onChanged: (val) => setState(() => search = val),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => sync.syncNow(),
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final b = filtered[i];

                  IconData icon;
                  Color color;

                  switch (b.synced) {
                    case "yes":
                      icon = Icons.cloud_done;
                      color = Colors.green;
                      break;
                    case "update":
                      icon = Icons.refresh;
                      color = Colors.orange;
                      break;
                    case "delete":
                      icon = Icons.delete;
                      color = Colors.grey;
                      break;
                    default:
                      icon = Icons.cloud_off;
                      color = Colors.red;
                  }

                  return ListTile(
                    title: Text(b.name ?? "No Name"),
                    subtitle: Text(b.idNumber ?? ""),
                    leading: Icon(icon, color: color),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                BeneficiaryDetailScreen(beneficiary: b)),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
