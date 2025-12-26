import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/beneficiary.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../db/hive_manager.dart';

class BeneficiaryFormScreen extends StatefulWidget {
  final Beneficiary? beneficiary;

  const BeneficiaryFormScreen({super.key, this.beneficiary});

  @override
  State<BeneficiaryFormScreen> createState() => _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState extends State<BeneficiaryFormScreen> {
  final _f = GlobalKey<FormState>();

  // Controllers
  final nameCtrl = TextEditingController();
  final idNumberCtrl = TextEditingController();
  final indicatorCtrl = TextEditingController();
  final dateCtrl = TextEditingController();

  String? ipName;
  String? sector;

  List<String> ipNames = [];
  List<String> sectors = [];

  bool checkingDuplicate = false;
  bool isDuplicate = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();

    if (widget.beneficiary != null) {
      final b = widget.beneficiary!;
      nameCtrl.text = b.name ?? "";
      idNumberCtrl.text = b.idNumber ?? "";
      indicatorCtrl.text = b.indicator ?? "";
      dateCtrl.text = b.date ?? "";
      ipName = b.ipName;
      sector = b.sector;
    }
  }

  Future<void> _loadDropdowns() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth);

    ipNames = await api.fetchDistinctIpNames();
    sectors = await api.fetchDistinctSectors();
    setState(() {});
  }

  // Duplicate check (local + remote)
  Future<void> checkDuplicate() async {
    setState(() => checkingDuplicate = true);

    final idNum = idNumberCtrl.text.trim();

    // Local check
    final existsLocal = HiveManager.beneficiaries.values
        .any((b) => b.idNumber == idNum && b.uuid != widget.beneficiary?.uuid);

    if (existsLocal) {
      setState(() {
        isDuplicate = true;
        checkingDuplicate = false;
      });
      return;
    }

    // Remote check
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth);

    final remote = await api.checkDuplicateID(idNum);

    setState(() {
      isDuplicate = remote;
      checkingDuplicate = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.beneficiary == null
            ? "Add Beneficiary"
            : "Edit Beneficiary"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _f,
          child: ListView(
            children: [
              // -------------------------
              // IP Name (Mandatory)
              // -------------------------
              DropdownButtonFormField<String>(
                value: ipName,
                items: ipNames
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration: const InputDecoration(labelText: "IP Name *"),
                onChanged: (v) => setState(() => ipName = v),
                validator: (v) => v == null ? "Required" : null,
              ),

              const SizedBox(height: 12),

              // -------------------------
              // Sector (Mandatory)
              // -------------------------
              DropdownButtonFormField<String>(
                value: sector,
                items: sectors
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                decoration: const InputDecoration(labelText: "Sector *"),
                onChanged: (v) => setState(() => sector = v),
                validator: (v) => v == null ? "Required" : null,
              ),

              const SizedBox(height: 12),

              // -------------------------
              // Name
              // -------------------------
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Name *"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 12),

              // -------------------------
              // ID Number
              // -------------------------
              TextFormField(
                controller: idNumberCtrl,
                decoration: const InputDecoration(labelText: "ID Number *"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
                onChanged: (_) => checkDuplicate(),
              ),

              if (checkingDuplicate)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text("Checking duplicates...",
                      style: TextStyle(color: Colors.orange)),
                ),

              if (isDuplicate)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text("Duplicate ID Number",
                      style: TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 12),

              // Indicator
              TextFormField(
                controller: indicatorCtrl,
                decoration: const InputDecoration(labelText: "Indicator"),
              ),

              const SizedBox(height: 12),

              // Date
              TextFormField(
                controller: dateCtrl,
                decoration:
                    const InputDecoration(labelText: "Date (YYYY-MM-DD)"),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save"),
                onPressed: () async {
                  if (!_f.currentState!.validate() || isDuplicate) return;

                  final b = widget.beneficiary ??
                      Beneficiary(
                        createdBy: auth.currentUser?.username,
                        deleted: false,
                        synced: "no",
                      );

                  b.name = nameCtrl.text.trim();
                  b.idNumber = idNumberCtrl.text.trim();
                  b.indicator = indicatorCtrl.text.trim();
                  b.date = dateCtrl.text.trim();
                  b.ipName = ipName;
                  b.sector = sector;

                  if (widget.beneficiary == null) {
                    // CREATE
                    b.synced = "no";
                    await HiveManager.beneficiaries.add(b);

                    await HiveManager.pushToQueue({
                      "action": "create",
                      "uuid": b.uuid,
                      "payload": b.toJson(),
                    });
                  } else {
                    // UPDATE
                    b.synced = "update";
                    await b.save();

                    await HiveManager.pushToQueue({
                      "action": "update",
                      "uuid": b.uuid,
                      "payload": b.toJson(),
                    });
                  }

                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
