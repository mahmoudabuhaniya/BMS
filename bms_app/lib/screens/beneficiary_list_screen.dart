import 'package:flutter/material.dart';
import '../offline/beneficiary_repository.dart';
import '../models/beneficiary.dart';
import '../offline/sync_service.dart';
import '../services/token_service.dart';
import 'beneficiary_form_screen.dart';

class BeneficiaryListScreen extends StatefulWidget {
  final bool showDeleted;

  const BeneficiaryListScreen({super.key, required this.showDeleted});

  @override
  State<BeneficiaryListScreen> createState() => _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends State<BeneficiaryListScreen> {
  List<Beneficiary> items = [];
  String username = "";
  List<String> groups = [];

  bool get isAdmin => groups.contains("Admin") || groups.contains("Manager");

  @override
  void initState() {
    super.initState();
    _loadProfile().then((_) => _loadData());
  }

  Future<void> _loadProfile() async {
    username = await TokenService.getUsername() ?? "";
    groups = await TokenService.getGroups();
  }

  Future<void> _loadData() async {
    final list = await BeneficiaryRepository.getAll();

    items =
        list.where((b) => widget.showDeleted ? b.deleted : !b.deleted).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.showDeleted ? "Deleted Records" : "Beneficiaries")),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) => _buildTile(items[i]),
        ),
      ),
    );
  }

  Widget _buildTile(Beneficiary b) {
    return ListTile(
      title: Text(b.name ?? "Unknown"),
      subtitle: Text("ID: ${b.idNumber ?? '-'}"),
      trailing: _syncIcon(b.synced),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BeneficiaryFormScreen(existing: b)),
      ),
    );
  }

  Widget _syncIcon(String synced) {
    switch (synced) {
      case "yes":
        return const Icon(Icons.cloud_done, color: Colors.green);
      case "update":
        return const Icon(Icons.refresh, color: Colors.orange);
      case "delete":
        return const Icon(Icons.delete, color: Colors.grey);
      default:
        return const Icon(Icons.cloud_off, color: Colors.red);
    }
  }
}
