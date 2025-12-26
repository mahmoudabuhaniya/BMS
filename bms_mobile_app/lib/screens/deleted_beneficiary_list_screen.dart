import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../db/hive_manager.dart';
import '../models/beneficiary.dart';
import '../theme/app_theme.dart';
import '../widgets/sync_status_badge.dart';
import '../services/auth_service.dart';

class DeletedBeneficiaryListScreen extends StatefulWidget {
  const DeletedBeneficiaryListScreen({super.key});

  @override
  State<DeletedBeneficiaryListScreen> createState() =>
      _DeletedBeneficiaryListScreenState();
}

class _DeletedBeneficiaryListScreenState
    extends State<DeletedBeneficiaryListScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  String query = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deleted Beneficiaries"),
        backgroundColor: AppTheme.unicefBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: "Search deleted by Name, ID…",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => setState(() => query = v.trim().toLowerCase()),
            ),
          ),

          // LIST OF DELETED BENEFICIARIES
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: HiveManager.beneficiaries.listenable(),
              builder: (context, box, _) {
                List<Beneficiary> list = box.values
                    .cast<Beneficiary>()
                    .where((b) => b.deleted == true)
                    .toList();

                final user = AuthService.currentUserStatic;

                // ROLE FILTER
                if (user != null &&
                    user.groups != "Admin" &&
                    user.groups != "Manager") {
                  list =
                      list.where((b) => b.createdBy == user.username).toList();
                }

                // SEARCH FILTER
                if (query.isNotEmpty) {
                  list = list.where((b) {
                    return (b.name ?? "").toLowerCase().contains(query) ||
                        (b.idNumber ?? "").toLowerCase().contains(query);
                  }).toList();
                }

                if (list.isEmpty) {
                  return const Center(
                    child: Text("No deleted beneficiaries found"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _deletedCard(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------
  // SINGLE CARD
  // -----------------------------------------------------
  Widget _deletedCard(Beneficiary b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // name & sync badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                b.name ?? "Unnamed",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SyncStatusBadge(status: b.synced),
            ],
          ),

          const SizedBox(height: 6),
          Text("ID Number: ${b.idNumber ?? '-'}"),
          Text("IP: ${b.ipName ?? '-'}"),
          Text("Sector: ${b.sector ?? '-'}"),

          const SizedBox(height: 12),

          Row(
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.restore, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                label: const Text("Restore"),
                onPressed: () => _restore(b),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.delete_forever, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                label: const Text("Delete Permanently"),
                onPressed: () => _deleteForever(b),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------
  // RESTORE → SEND ORCHESTRATION ACTION = "restore"
  // -----------------------------------------------------
  Future<void> _restore(Beneficiary b) async {
    final user = AuthService.currentUserStatic;
    final now = DateTime.now().toIso8601String();

    // Local update
    b.deleted = false;
    b.undeletedAt = now;
    b.undeletedBy = user?.username ?? "mobile";
    b.synced = "no";

    await HiveManager.saveBeneficiary(b);

    // Queue orchestration request
    await HiveManager.pushToQueue({
      "action": "restore",
      "payload": {
        "id": b.id, // REQUIRED for orchestration
        "undeleted_by": b.undeletedBy,
        "undeleted_at": b.undeletedAt,
      },
    });

    if (mounted) setState(() {});
  }

  // -----------------------------------------------------
  // PERMANENT DELETE → LOCAL ONLY
  // -----------------------------------------------------
  Future<void> _deleteForever(Beneficiary b) async {
    await HiveManager.beneficiaries.delete(b.localId);
    if (mounted) setState(() {});
  }
}
