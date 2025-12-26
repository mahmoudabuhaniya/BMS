import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import '../services/sync_service.dart';
import '../db/hive_manager.dart';
import '../models/beneficiary.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sync_banner.dart';
import '../widgets/sync_status_badge.dart';
import 'beneficiary_form_screen.dart';

class BeneficiaryListScreen extends StatefulWidget {
  const BeneficiaryListScreen({super.key});

  @override
  State<BeneficiaryListScreen> createState() => _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends State<BeneficiaryListScreen> {
  final TextEditingController searchCtrl = TextEditingController();
  String query = "";

  late SyncService _sync;

  @override
  void initState() {
    super.initState();

    // Load initial offline data
    _loadLocal();

    // Sync listener
    _sync = Provider.of<SyncService>(context, listen: false);
    _sync.addListener(_onSyncUpdate);

    // Live search
    searchCtrl.addListener(() {
      setState(() => query = searchCtrl.text.toLowerCase().trim());
    });
  }

  void _onSyncUpdate() {
    if (!mounted) return;

    if (!_sync.isSyncing) {
      _loadLocal();
    }
  }

  void _loadLocal() {
    setState(() {}); // just refresh
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncUpdate);
    searchCtrl.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // BENEFICIARY CARD
  // ----------------------------------------------------------
  Widget _card(Beneficiary b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BeneficiaryFormScreen(beneficiary: b),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + synced badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      b.name ?? "Unnamed",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.unicefBlue,
                      ),
                    ),
                  ),
                  SyncStatusBadge(status: b.synced),
                ],
              ),

              const SizedBox(height: 8),
              Text("ID Number: ${b.idNumber ?? '-'}"),
              Text("IP: ${b.ipName ?? '-'}"),
              Text("Sector: ${b.sector ?? '-'}"),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // MAIN BUILD
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUserStatic;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Beneficiaries"),
        backgroundColor: AppTheme.unicefBlue,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SyncBanner(),

          // Search box
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: "Search by Name, ID, IP, Sector…",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // MAIN LIST
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: HiveManager.beneficiaries.listenable(),
              builder: (context, box, _) {
                List<Beneficiary> list =
                    box.values.cast<Beneficiary>().toList();

                // ------------------------------------------
                // FILTER 1 → Hide Deleted items
                // ------------------------------------------
                list = list.where((b) => b.deleted != true).toList();

                // ------------------------------------------
                // FILTER 2 → User role restrictions
                // ------------------------------------------
                if (user != null &&
                    user.groups != "Admin" &&
                    user.groups != "Manager") {
                  list =
                      list.where((b) => b.createdBy == user.username).toList();
                }

                // ------------------------------------------
                // FILTER 3 → Search
                // ------------------------------------------
                if (query.isNotEmpty) {
                  list = list.where((b) {
                    return (b.name ?? "").toLowerCase().contains(query) ||
                        (b.idNumber ?? "").toLowerCase().contains(query) ||
                        (b.ipName ?? "").toLowerCase().contains(query) ||
                        (b.sector ?? "").toLowerCase().contains(query);
                  }).toList();
                }

                // ------------------------------------------
                // SORT → Highest server ID first
                // ------------------------------------------
                list.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

                if (list.isEmpty) {
                  return const Center(
                    child: Text("No beneficiaries found"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _card(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
