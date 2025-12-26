import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/beneficiary.dart';
import '../offline/beneficiary_repository.dart';
import '../offline/pending_queue.dart';
import '../offline/dropdown_loader.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';

class BeneficiaryFormScreen extends StatefulWidget {
  final Beneficiary? existing;

  const BeneficiaryFormScreen({super.key, this.existing});

  @override
  State<BeneficiaryFormScreen> createState() => _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState extends State<BeneficiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  // Controllers
  final nameCtrl = TextEditingController();
  final idNumberCtrl = TextEditingController();
  final indicatorCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final governorateCtrl = TextEditingController();
  final municipalityCtrl = TextEditingController();
  final neighborhoodCtrl = TextEditingController();
  final siteNameCtrl = TextEditingController();
  final parentCtrl = TextEditingController();
  final spouseCtrl = TextEditingController();

  // Dropdowns
  List<String> ipNames = [];
  List<String> sectors = [];
  String? selectedIpName;
  String? selectedSector;
  String? gender;
  String? disability;

  bool loadingDropdowns = true;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    _loadExisting();
  }

  Future<void> _loadDropdowns() async {
    final map = await DropdownLoader.load();
    ipNames = map["ipnames"]!;
    sectors = map["sectors"]!;

    setState(() => loadingDropdowns = false);
  }

  void _loadExisting() {
    final b = widget.existing;
    if (b == null) return;

    nameCtrl.text = b.name ?? "";
    idNumberCtrl.text = b.idNumber ?? "";
    indicatorCtrl.text = b.indicator ?? "";
    dateCtrl.text = b.date ?? "";
    phoneCtrl.text = b.phoneNumber ?? "";
    dobCtrl.text = b.dateOfBirth ?? "";
    ageCtrl.text = b.age?.toString() ?? "";
    governorateCtrl.text = b.governorate ?? "";
    municipalityCtrl.text = b.municipality ?? "";
    neighborhoodCtrl.text = b.neighborhood ?? "";
    siteNameCtrl.text = b.siteName ?? "";
    parentCtrl.text = b.parentId ?? "";
    spouseCtrl.text = b.spouseId ?? "";

    selectedIpName = b.ipName;
    selectedSector = b.sector;
    gender = b.gender;
    disability = b.disabilityStatus == true ? "True" : "False";
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final username = await TokenService.getUsername() ?? "";

    // New or existing ID
    final id = widget.existing?.id ?? const Uuid().v4();

    final b = Beneficiary(
      id: id,
      inFormId: widget.existing?.inFormId,
      recordId: widget.existing?.recordId,
      instanceId: widget.existing?.instanceId,
      ipName: selectedIpName,
      sector: selectedSector,
      indicator:
          indicatorCtrl.text.trim().isEmpty ? null : indicatorCtrl.text.trim(),
      date: dateCtrl.text.trim().isEmpty ? null : dateCtrl.text.trim(),
      name: nameCtrl.text.trim(),
      idNumber: idNumberCtrl.text.trim(),
      phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      dateOfBirth: dobCtrl.text.trim().isEmpty ? null : dobCtrl.text.trim(),
      age: ageCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(ageCtrl.text.trim()),
      gender: gender,
      governorate: governorateCtrl.text.trim().isEmpty
          ? null
          : governorateCtrl.text.trim(),
      municipality: municipalityCtrl.text.trim().isEmpty
          ? null
          : municipalityCtrl.text.trim(),
      neighborhood: neighborhoodCtrl.text.trim().isEmpty
          ? null
          : neighborhoodCtrl.text.trim(),
      siteName:
          siteNameCtrl.text.trim().isEmpty ? null : siteNameCtrl.text.trim(),
      disabilityStatus: disability == "True",
      parentId: parentCtrl.text.trim().isEmpty ? null : parentCtrl.text.trim(),
      spouseId: spouseCtrl.text.trim().isEmpty ? null : spouseCtrl.text.trim(),
      submissionTime: DateTime.now().toIso8601String(),
      createdBy: username,
      synced: widget.existing == null ? "no" : "update",
      deleted: false,
    );

    await BeneficiaryRepository.save(b);
    await PendingQueue.addCreateOrUpdate(b);

    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loadingDropdowns) {
      return const Scaffold(
        body:
            Center(child: CircularProgressIndicator(color: Color(0xFF1E88E5))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.existing == null ? "Add Beneficiary" : "Edit Beneficiary"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _dropdown("IP Name", ipNames, selectedIpName,
                  (v) => setState(() => selectedIpName = v),
                  required: true),
              const SizedBox(height: 12),
              _dropdown("Sector", sectors, selectedSector,
                  (v) => setState(() => selectedSector = v),
                  required: true),
              const SizedBox(height: 12),
              _input(nameCtrl, "Name", required: true),
              const SizedBox(height: 12),
              _input(idNumberCtrl, "ID Number", required: true),
              const SizedBox(height: 12),
              _input(indicatorCtrl, "Indicator"),
              const SizedBox(height: 12),
              _input(dateCtrl, "Date (YYYY-MM-DD)"),
              const SizedBox(height: 12),
              _input(parentCtrl, "Parent ID"),
              const SizedBox(height: 12),
              _input(spouseCtrl, "Spouse ID"),
              const SizedBox(height: 12),
              _input(phoneCtrl, "Phone Number"),
              const SizedBox(height: 12),
              _input(dobCtrl, "Date of Birth"),
              const SizedBox(height: 12),
              _input(ageCtrl, "Age"),
              const SizedBox(height: 12),
              _dropdown("Gender", ["Male", "Female"], gender,
                  (v) => setState(() => gender = v)),
              const SizedBox(height: 12),
              _input(governorateCtrl, "Governorate"),
              const SizedBox(height: 12),
              _input(municipalityCtrl, "Municipality"),
              const SizedBox(height: 12),
              _input(neighborhoodCtrl, "Neighborhood"),
              const SizedBox(height: 12),
              _input(siteNameCtrl, "Site Name"),
              const SizedBox(height: 12),
              _dropdown("Disability Status", ["True", "False"], disability,
                  (v) => setState(() => disability = v)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text("SAVE", style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _input(TextEditingController ctrl, String label,
      {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? "Required" : null
          : null,
    );
  }

  Widget _dropdown(String label, List<String> items, String? value,
      Function(String?) onChanged,
      {bool required = false}) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: required && value == null ? (_) => "Required" : null,
    );
  }
}
