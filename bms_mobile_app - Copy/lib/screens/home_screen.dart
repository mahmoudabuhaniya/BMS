import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/unicef_button.dart';
import 'beneficiary_list_screen.dart';
import 'deleted_beneficiary_list_screen.dart';
import 'beneficiary_form_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final sync = Provider.of<SyncService>(context);

    final name =
        "${auth.currentUser?.firstName ?? ''} ${auth.currentUser?.lastName ?? ''}"
            .trim();

    final groupList = auth.currentUser?.groups ?? [];
    final groups = groupList.isEmpty ? "No Groups" : groupList.join(", ");

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("UNICEF Beneficiary System"),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: OfflineIndicator(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER CARD
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        "Welcome, $name",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Groups: $groups",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Chip(
                        label: Text(
                          sync.isSyncing ? "Syncing..." : "Synced",
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor:
                            sync.isSyncing ? Colors.orange : Colors.green,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- CENTERED BUTTONS ---
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: UnicefButton(
                      text: "Add New Beneficiary",
                      icon: Icons.person_add,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BeneficiaryFormScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: UnicefButton(
                      text: "View All Beneficiaries",
                      icon: Icons.list_alt,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BeneficiaryListScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: UnicefButton(
                      text: "Deleted Beneficiaries",
                      icon: Icons.delete,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const DeletedBeneficiaryListScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: UnicefButton(
                      text: sync.isSyncing ? "Syncing..." : "Sync Now",
                      icon: Icons.sync,
                      onPressed: () => sync.syncNow(),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => auth.logout(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
