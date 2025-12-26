import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/beneficiary.dart';
import '../db/hive_manager.dart';
import '../services/sync_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class BeneficiaryFormScreen extends StatefulWidget {
  final Beneficiary? beneficiary;

  const BeneficiaryFormScreen({super.key, this.beneficiary});

  @override
  State<BeneficiaryFormScreen> createState() => _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState extends State<BeneficiaryFormScreen> {
  final _form = GlobalKey<FormState>();

  final nameCtrl = TextEditingController();
  final idCtrl = TextEditingController();
  final indicatorCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  String? ipName;
  String? sector;
  String? gender;
  String? disability;

  List<String> ipOptions = [];
  List<String> sectorOptions = [];

  @override
  void initState() {
    super.initState();
    _loadDropdowns();

    if (widget.beneficiary != null) {
      final b = widget.beneficiary!;
      nameCtrl.text = b.name ?? "";
      idCtrl.text = b.idNumber ?? "";
      indicatorCtrl.text = b.indicator ?? "";
      phoneCtrl.text = b.phoneNumber ?? "";
      dobCtrl.text = b.dateOfBirth ?? "";
      dateCtrl.text = b.date ?? "";

      ipName = b.ipName;
      sector = b.sector;
      gender = b.gender;
      disability = b.disabilityStatus;
    }
  }

  Future<void> _loadDropdowns() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth);

    ipOptions = await api.fetchDistinctIPNames();
    sectorOptions = await api.fetchDistinctSectors();

    setState(() {});
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    final newItem = Beneficiary(
      uuid: widget.beneficiary?.uuid ?? const Uuid().v4(),
      name: nameCtrl.text.trim(),
      idNumber: idCtrl.text.trim(),
      ipName: ipName,
      sector: sector,
      indicator: indicatorCtrl.text.trim(),
      phoneNumber: phoneCtrl.text.trim(),
      dateOfBirth: dobCtrl.text.trim().isEmpty ? null : dobCtrl.text.trim(),
      date: dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim(),
      gender: gender,
      disabilityStatus: disability,
      createdAt:
          widget.beneficiary?.createdAt ?? DateTime.now().toIso8601String(),
      deleted: false,
      synced: "pending",
    );

    await HiveManager.saveBeneficiary(newItem);
    await HiveManager.queueSave("create_or_update", newItem.toJson());

    final sync = Provider.of<SyncService>(context, listen: false);
    sync.triggerAutoSync();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.beneficiary == null
              ? "Create Beneficiary"
              : "Edit Beneficiary",
        ),
        backgroundColor: AppTheme.unicefBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Name *"),
                validator: (v) => v!.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: idCtrl,
                decoration: const InputDecoration(labelText: "ID Number *"),
                validator: (v) => v!.trim().isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: ipName,
                items: ipOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration: const InputDecoration(labelText: "IP Name *"),
                validator: (v) => v == null ? "Required" : null,
                onChanged: (v) => setState(() => ipName = v),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: sector,
                items: sectorOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration: const InputDecoration(labelText: "Sector *"),
                validator: (v) => v == null ? "Required" : null,
                onChanged: (v) => setState(() => sector = v),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: gender,
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                ],
                decoration: const InputDecoration(labelText: "Gender"),
                onChanged: (v) => setState(() => gender = v),
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                value: disability,
                items: const [
                  DropdownMenuItem(value: "True", child: Text("Yes")),
                  DropdownMenuItem(value: "False", child: Text("No")),
                ],
                decoration: const InputDecoration(labelText: "Disability"),
                onChanged: (v) => setState(() => disability = v),
              ),
              const SizedBox(height: 25),

              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.unicefBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 14,
                  ),
                ),
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
