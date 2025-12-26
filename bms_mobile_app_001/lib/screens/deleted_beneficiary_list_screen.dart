import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/beneficiary.dart';
import '../db/hive_manager.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class DeletedBeneficiaryListScreen extends StatefulWidget {
  const DeletedBeneficiaryListScreen({super.key});

  @override
  State<DeletedBeneficiaryListScreen> createState() =>
      _DeletedBeneficiaryListScreenState();
}

class _DeletedBeneficiaryListScreenState
    extends State<DeletedBeneficiaryListScreen> {
  List<Beneficiary> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadLocal();
    _refreshRemote();
  }

  void _loadLocal() {
    items = HiveManager.beneficiaries.values
        .where((b) => b.deleted == true)
        .toList()
      ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));

    if (mounted) setState(() => loading = false);
  }

  Future<void> _refreshRemote() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth);

    final remote = await api.fetchBeneficiaries();

    if (!mounted) return;

    if (remote.isNotEmpty) {
      final box = HiveManager.beneficiaries;
      await box.clear();
      for (var b in remote) {
        await box.add(b);
      }
    }

    if (mounted) _loadLocal();
  }

  Widget _card(Beneficiary b) {
    return Card(
      color: Colors.red.shade50,
      child: ListTile(
        title: Text(
          b.name ?? "Unnamed",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("ID: ${b.idNumber ?? '-'}"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Deleted Beneficiaries")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshRemote,
              child: items.isEmpty
                  ? const Center(child: Text("No deleted beneficiaries"))
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (_, i) => _card(items[i]),
                    ),
            ),
    );
  }
}
