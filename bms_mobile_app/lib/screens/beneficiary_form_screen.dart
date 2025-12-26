import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/beneficiary.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../db/hive_manager.dart';
import '../theme/app_theme.dart';

class BeneficiaryFormScreen extends StatefulWidget {
  final Beneficiary? beneficiary; // null → new item

  const BeneficiaryFormScreen({super.key, this.beneficiary});

  @override
  State<BeneficiaryFormScreen> createState() => _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState extends State<BeneficiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameCtrl = TextEditingController();
  final idCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final indicatorCtrl = TextEditingController();
  final governorateCtrl = TextEditingController();
  final municipalityCtrl = TextEditingController();
  final neighborhoodCtrl = TextEditingController();
  final siteCtrl = TextEditingController();
  final ageCtrl = TextEditingController();

  // Dropdowns
  String? selectedGender;
  String? selectedDisability;
  String? selectedIP;
  String? selectedSector;

  List<String> ipNames = [];
  List<String> sectors = [];

  bool loading = false;
  bool idDuplicate = false;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    idCtrl.addListener(_checkDuplicate);

    if (widget.beneficiary != null) {
      final b = widget.beneficiary!;
      nameCtrl.text = b.name ?? "";
      idCtrl.text = b.idNumber ?? "";
      phoneCtrl.text = b.phoneNumber ?? "";
      dobCtrl.text = b.dateOfBirth ?? "";
      dateCtrl.text = b.date ?? "";
      indicatorCtrl.text = b.indicator ?? "";
      governorateCtrl.text = b.governorate ?? "";
      municipalityCtrl.text = b.municipality ?? "";
      neighborhoodCtrl.text = b.neighborhood ?? "";
      siteCtrl.text = b.siteName ?? "";
      ageCtrl.text = b.age ?? "";
      selectedGender = b.gender;
      selectedDisability = b.disabilityStatus;
      selectedIP = b.ipName;
      selectedSector = b.sector;
    }
  }

  // -----------------------------------------------------------------
  // DUPLICATE CHECK
  // -----------------------------------------------------------------
  void _checkDuplicate() {
    final input = idCtrl.text.trim();
    if (input.isEmpty) {
      setState(() => idDuplicate = false);
      return;
    }

    final all = HiveManager.beneficiaries.values.toList();
    final exists = all.any((x) =>
        x.idNumber == input &&
        (widget.beneficiary == null ||
            x.localId != widget.beneficiary!.localId));

    setState(() => idDuplicate = exists);
  }

  Future<void> _loadDropdowns() async {
    final api = ApiService(Provider.of<AuthService>(context, listen: false));
    ipNames = await api.fetchIPNames();
    sectors = await api.fetchSectors();
    setState(() {});
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    idCtrl.dispose();
    phoneCtrl.dispose();
    dobCtrl.dispose();
    dateCtrl.dispose();
    indicatorCtrl.dispose();
    governorateCtrl.dispose();
    municipalityCtrl.dispose();
    neighborhoodCtrl.dispose();
    siteCtrl.dispose();
    ageCtrl.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------------
  // SAVE (CREATE or UPDATE)
  // -----------------------------------------------------------------
  Future<void> _save() async {
    if (idDuplicate) {
      return _showDialog("Duplicate", "This ID Number already exists.");
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final user = AuthService.currentUserStatic;
    final now = DateTime.now().toIso8601String();

    Beneficiary b = Beneficiary(
      id: widget.beneficiary?.id,
      localId:
          widget.beneficiary?.localId ?? DateTime.now().millisecondsSinceEpoch,
      name: nameCtrl.text.trim(),
      idNumber: idCtrl.text.trim(),
      ipName: selectedIP,
      sector: selectedSector,
      phoneNumber: phoneCtrl.text.trim(),
      date: dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim(),
      dateOfBirth: dobCtrl.text.trim().isEmpty ? null : dobCtrl.text.trim(),
      age: ageCtrl.text.trim().isEmpty ? null : ageCtrl.text.trim(),
      gender: selectedGender,
      disabilityStatus: selectedDisability,
      indicator: indicatorCtrl.text.trim(),
      governorate: governorateCtrl.text.trim(),
      municipality: municipalityCtrl.text.trim(),
      neighborhood: neighborhoodCtrl.text.trim(),
      siteName: siteCtrl.text.trim(),
      submissionTime: now,

      // NEW FIELDS REQUIRED BY ORCHESTRATION
      createdBy: widget.beneficiary == null
          ? (user?.username ?? "mobile")
          : widget.beneficiary!.createdBy,
      updatedBy: user?.username ?? "mobile",
      updatedAt: now,
      deleted: false,
    );

    // Save offline copy
    await HiveManager.saveBeneficiary(b);

    // Queue for orchestration API
    await HiveManager.pushToQueue({
      "action": widget.beneficiary == null ? "create" : "update",
      "payload": b.toJson(),
    });

    setState(() => loading = false);

    _showDialog("Saved", "Beneficiary saved successfully.", close: true);
  }

  // -----------------------------------------------------------------
  // DELETE (SOFT DELETE REQUEST)
  // -----------------------------------------------------------------
  Future<void> _delete() async {
    final b = widget.beneficiary;
    if (b == null || b.id == null) return;

    final user = AuthService.currentUserStatic;
    final now = DateTime.now().toIso8601String();

    await HiveManager.pushToQueue({
      "action": "delete",
      "payload": {
        "id": b.id,
        "deleted_by": user?.username ?? "mobile",
        "deleted_at": now,
      }
    });

    _showDialog("Deleted", "Beneficiary marked as deleted.", close: true);
  }

  // -----------------------------------------------------------------
  // RESTORE
  // -----------------------------------------------------------------
  Future<void> _restore() async {
    final b = widget.beneficiary;
    if (b == null || b.id == null) return;

    final user = AuthService.currentUserStatic;
    final now = DateTime.now().toIso8601String();

    await HiveManager.pushToQueue({
      "action": "restore",
      "payload": {
        "id": b.id,
        "undeleted_by": user?.username ?? "mobile",
        "undeleted_at": now,
      }
    });

    _showDialog("Restored", "Beneficiary restored.", close: true);
  }

  // -----------------------------------------------------------------
  // UI
  // -----------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.beneficiary != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Beneficiary" : "Add Beneficiary"),
        backgroundColor: AppTheme.unicefBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: isEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _delete,
                ),
                if (widget.beneficiary!.deleted == true)
                  IconButton(
                    icon: const Icon(Icons.restore, color: Colors.white),
                    onPressed: _restore,
                  ),
              ]
            : [],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _section("Basic Info"),
                  _field(nameCtrl, "Name", required: true),
                  _field(idCtrl, "ID Number", required: true),
                  if (idDuplicate)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        "⚠ ID already exists",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  _dropdown(
                      "IP Name", ipNames, selectedIP, (v) => selectedIP = v,
                      required: true),
                  _dropdown("Sector", sectors, selectedSector,
                      (v) => selectedSector = v,
                      required: true),
                  _section("More Details"),
                  _field(indicatorCtrl, "Indicator"),
                  _date(dateCtrl, "Date"),
                  _field(phoneCtrl, "Phone"),
                  _date(dobCtrl, "Date of Birth"),
                  _field(ageCtrl, "Age"),
                  _dropdown("Gender", ["M", "F"], selectedGender,
                      (v) => selectedGender = v),
                  _field(governorateCtrl, "Governorate"),
                  _field(municipalityCtrl, "Municipality"),
                  _field(neighborhoodCtrl, "Neighborhood"),
                  _field(siteCtrl, "Site Name"),
                  _dropdown("Disability", ["Yes", "No"], selectedDisability,
                      (v) => selectedDisability = v),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.unicefBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _save,
                    child: const Text("Save"),
                  ),
                ],
              ),
            ),
    );
  }

  // -----------------------------------------------------------------
  // Widgets
  // -----------------------------------------------------------------

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
          t,
          style: const TextStyle(
              color: AppTheme.unicefBlue,
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      );

  Widget _field(TextEditingController c, String label,
      {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: required
            ? (v) => v!.trim().isEmpty ? "$label is required" : null
            : null,
      ),
    );
  }

  Widget _date(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        readOnly: true,
        controller: c,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            firstDate: DateTime(1960),
            lastDate: DateTime(2090),
            initialDate: DateTime.now(),
          );
          if (d != null) {
            c.text =
                "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
          }
        },
      ),
    );
  }

  Widget _dropdown(
    String label,
    List<String> items,
    String? selected,
    Function(String?) onChange, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selected,
        items: items
            .map((x) => DropdownMenuItem(value: x, child: Text(x)))
            .toList(),
        onChanged: onChange,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator:
            required ? (v) => v == null ? "$label is required" : null : null,
      ),
    );
  }

  // Dialog
  void _showDialog(String title, String msg, {bool close = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context);
              if (close) Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }
}
