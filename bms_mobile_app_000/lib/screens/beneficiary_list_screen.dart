import 'package:flutter/material.dart';

import '../db/hive_manager.dart';
import '../models/beneficiary.dart';
import '../widgets/sync_status_cloud.dart';
import '../theme/app_theme.dart';
import 'beneficiary_form_screen.dart';

class BeneficiaryListScreen extends StatefulWidget {
  const BeneficiaryListScreen({super.key});

  @override
  State<BeneficiaryListScreen> createState() => _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends State<BeneficiaryListScreen> {
  List<Beneficiary> items = [];

  final TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final box = HiveManager.beneficiariesBox;
    final raw = box.values.where((b) => b.deleted != true).toList();

    print("BENEFICIARIES IN HIVE: ${box.values.length}");
    for (var b in box.values) {
      print("ROW: id=${b.id}, name=${b.name}, deleted=${b.deleted}");
    }

    // FIXED SORT
    raw.sort((a, b) {
      final aDate = DateTime.tryParse(a.createdAt ?? "") ?? DateTime(2000);
      final bDate = DateTime.tryParse(b.createdAt ?? "") ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

    setState(() => items = raw);
  }

  void _search(String q) {
    final box = HiveManager.beneficiariesBox;

    if (q.trim().isEmpty) {
      _load();
      return;
    }

    final filtered = box.values.where((b) => b.deleted != true).toList();

    setState(() => items = filtered);
    print(items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Beneficiaries"),
        backgroundColor: AppTheme.unicefBlue,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.unicefBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BeneficiaryFormScreen()),
          );
          _load();
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                labelText: "Search by name",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text("No records"))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final b = items[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          title: Text(
                            b.name ?? "No Name",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("ID: ${b.idNumber ?? '-'}"),
                          trailing: SyncStatusCloud(
                            status: b.synced ?? "pending",
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    BeneficiaryFormScreen(beneficiary: b),
                              ),
                            );
                            _load();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
