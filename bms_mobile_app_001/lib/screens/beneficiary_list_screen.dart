import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/beneficiary.dart';
import '../db/hive_manager.dart';
import '../services/sync_service.dart';
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
  List<Beneficiary> items = [];
  List<Beneficiary> filtered = [];

  bool loading = true;
  String query = "";

  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();

    final sync = Provider.of<SyncService>(context, listen: false);

    // reload hive after sync finishes
    sync.addListener(() {
      if (!sync.isSyncing) {
        _loadLocal();
      }
    });

    _loadLocal();
  }

  void _loadLocal() {
    final boxItems = HiveManager.beneficiaries.values.toList();

    items = boxItems.where((b) => b.deleted != true).toList()
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    _applyFilter();

    if (!mounted) return;
    setState(() => loading = false);
  }

  void _applyFilter() {
    final q = query.toLowerCase();

    filtered = items.where((b) {
      return (b.name ?? "").toLowerCase().contains(q) ||
          (b.idNumber ?? "").toLowerCase().contains(q) ||
          (b.ipName ?? "").toLowerCase().contains(q) ||
          (b.sector ?? "").toLowerCase().contains(q);
    }).toList();
  }

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
          ).then((_) => _loadLocal());
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    b.name ?? "Unnamed",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.unicefBlue,
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

  @override
  Widget build(BuildContext context) {
    final sync = Provider.of<SyncService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Beneficiaries"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: sync.manualSync,
          ),
        ],
      ),
      body: Column(
        children: [
          const SyncBanner(),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: "Search...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) {
                query = v;
                _applyFilter();

                if (!mounted) return;
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _card(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
