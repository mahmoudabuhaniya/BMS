import 'package:flutter/material.dart';
import '../offline/beneficiary_repository.dart';
import '../models/beneficiary.dart';

class DeletedBeneficiaryListScreen extends StatefulWidget {
  const DeletedBeneficiaryListScreen({super.key});

  @override
  State<DeletedBeneficiaryListScreen> createState() =>
      _DeletedBeneficiaryListScreenState();
}

class _DeletedBeneficiaryListScreenState
    extends State<DeletedBeneficiaryListScreen> {
  List<Beneficiary> items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await BeneficiaryRepository.getAll();
    items = list.where((b) => b.deleted).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Deleted Beneficiaries")),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) => ListTile(
          title: Text(items[i].name ?? ""),
          subtitle: Text(items[i].idNumber ?? ""),
        ),
      ),
    );
  }
}
