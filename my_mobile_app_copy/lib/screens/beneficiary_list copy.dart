import 'package:flutter/material.dart';
import '../models/beneficiary.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'beneficiary_form.dart';
import '../offline/dropdown_loader.dart';

class BeneficiaryListScreen extends StatefulWidget {
  final List<String> ipNames;
  final List<String> sectors;

  const BeneficiaryListScreen({
    super.key,
    required this.ipNames,
    required this.sectors,
  });

  @override
  State<BeneficiaryListScreen> createState() => _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends State<BeneficiaryListScreen> {
  List<Beneficiary> items = [];
  List<String> groups = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    groups = await TokenService.getGroups() ?? [];

    final apiItems = await ApiService().fetchBeneficiaries();

    final username = await TokenService.getUsername();

    if (!groups.contains("Admin") && !groups.contains("Manager")) {
      items = apiItems.where((b) => b.createdBy == username).toList();
    } else {
      items = apiItems;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Beneficiaries")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final b = items[i];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(b.ipName ?? "Unknown"),
              subtitle: Text("Sector: ${b.sector ?? '-'}"),
              trailing: const Icon(Icons.edit),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FutureBuilder(
                      future: DropdownLoader.loadDistinctValues(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                              child: CircularProgressIndicator());

                        final data = snapshot.data as Map<String, List<String>>;

                        return BeneficiaryFormScreen(
                          beneficiary: b,
                          ipNames: data["ip_names"]!,
                          sectors: data["sectors"]!,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
