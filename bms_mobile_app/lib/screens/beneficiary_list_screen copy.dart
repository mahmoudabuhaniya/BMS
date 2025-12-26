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
  List<Beneficiary> allItems = [];
  List<Beneficiary> filtered = [];
  bool loading = true;
  late SyncService _sync;

  void _applyFilter() {
    final q = query.toLowerCase().trim();

    filtered = allItems.where((b) {
      return (b.name ?? "").toLowerCase().contains(q) ||
          (b.idNumber ?? "").toLowerCase().contains(q) ||
          (b.ipName ?? "").toLowerCase().contains(q) ||
          (b.sector ?? "").toLowerCase().contains(q);
    }).toList();
  }

  void _loadLocal() {
    final user = AuthService.currentUserStatic;
    if (user == null) return;

    final list = HiveManager.getAll();

    List<Beneficiary> cleaned = list.where((b) => b.deleted != true).toList();

    if (user.groups != "Admin" && user.groups != "Manager") {
      cleaned = cleaned.where((b) => b.createdBy == user.username).toList();
    }

    cleaned.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    allItems = cleaned;
    _applyFilter();

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _loadLocal();

    _sync = Provider.of<SyncService>(context, listen: false);
    _sync.addListener(_onSyncUpdate);
  }

  void _onSyncUpdate() {
    if (!mounted) return;

    final sync = Provider.of<SyncService>(context, listen: false);
    if (!sync.isSyncing) {
      _loadLocal();
    }
  }

  @override
  void dispose() {
    _sync.removeListener(_onSyncUpdate);
    super.dispose();
  }

  // ----------------------------------------------------------
  // CARD UI
  // ----------------------------------------------------------
  Widget _card(Beneficiary b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5),
        ],
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
  // BUILD
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
              onChanged: (v) {
                setState(() => query = v);
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: HiveManager.beneficiaries.listenable(),
              builder: (context, box, _) {
                final user = AuthService.currentUserStatic;

                // 1) load from Hive
                List<Beneficiary> list =
                    box.values.cast<Beneficiary>().toList();

                // 2) remove deleted
                list = list.where((b) => b.deleted != true).toList();

                // Role filter
                if (user != null &&
                    user.groups != "Admin" &&
                    user.groups != "Manager") {
                  list =
                      list.where((b) => b.createdBy == user.username).toList();
                }
                // Search
                final q = query.toLowerCase().trim();
                if (q.isNotEmpty) {
                  list = list.where((b) {
                    return (b.name ?? "").toLowerCase().contains(q) ||
                        (b.idNumber ?? "").toLowerCase().contains(q) ||
                        (b.ipName ?? "").toLowerCase().contains(q) ||
                        (b.sector ?? "").toLowerCase().contains(q);
                  }).toList();
                }

                // Sort (descending by id; null as 0)
                list.sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

                if (list.isEmpty) {
                  return const Center(child: Text("No beneficiaries found"));
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
