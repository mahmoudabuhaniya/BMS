import 'package:flutter/material.dart';
import '../models/beneficiary.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import '../offline/dropdown_loader.dart';

class BeneficiaryFormScreen extends StatefulWidget {
  final Beneficiary? beneficiary;

  const BeneficiaryFormScreen({super.key, this.beneficiary});

  @override
  State<BeneficiaryFormScreen> createState() => _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState extends State<BeneficiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  // Controllers
  final _nameCtrl = TextEditingController();
  final _idNumberCtrl = TextEditingController();
  final _indicatorCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _parentIdCtrl = TextEditingController();
  final _spouseIdCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _govCtrl = TextEditingController();
  final _munCtrl = TextEditingController();
  final _neighCtrl = TextEditingController();
  final _siteCtrl = TextEditingController();
  final _householdCtrl = TextEditingController();

  List<String> _ipOptions = [];
  List<String> _sectorOptions = [];

  String? _selectedIpName;
  String? _selectedSector;
  String? _selectedGender;
  String? _selectedDisability; // "True" or "False"

  bool _loadingDropdowns = true;
  bool _saving = false;

  bool get _isEdit => widget.beneficiary != null;

  @override
  void initState() {
    super.initState();
    _initBeneficiary();
    _loadDropdowns();
  }

  void _initBeneficiary() {
    final b = widget.beneficiary;
    if (b == null) return;

    _selectedIpName = b.ipName;
    _selectedSector = b.sector;
    _nameCtrl.text = b.name ?? '';
    _idNumberCtrl.text = b.idNumber ?? '';
    _indicatorCtrl.text = b.indicator ?? '';
    _dateCtrl.text = b.date ?? '';
    _parentIdCtrl.text = b.parentId ?? '';
    _spouseIdCtrl.text = b.spouseId ?? '';
    _phoneCtrl.text = b.phoneNumber ?? '';
    _dobCtrl.text = b.dateOfBirth ?? '';
    _ageCtrl.text = b.age ?? '';
    _selectedGender = b.gender;
    _govCtrl.text = b.governorate ?? '';
    _munCtrl.text = b.municipality ?? '';
    _neighCtrl.text = b.neighborhood ?? '';
    _siteCtrl.text = b.siteName ?? '';
    _selectedDisability = b.disabilityStatus == true
        ? "True"
        : b.disabilityStatus == false
            ? "False"
            : null;

    _householdCtrl.text = b.householdId ?? '';
  }

  Future<void> _loadDropdowns() async {
    final data = await DropdownLoader.loadDistinctValues();
    setState(() {
      _ipOptions = List<String>.from(data["ip_names"] ?? []);
      _sectorOptions = List<String>.from(data["sectors"] ?? []);
      _loadingDropdowns = false;
    });
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final now = DateTime.now();
    final initial = DateTime.tryParse(controller.text) ?? now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      controller.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedIpName == null || _selectedSector == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("IP Name and Sector are required.")),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final username = await TokenService.getUsername() ?? "";
      final nowIso = DateTime.now().toIso8601String();
      final idNumber = _idNumberCtrl.text.trim();
      final existingId = widget.beneficiary?.id;

      // Duplicate remote check
      final duplicate =
          await _api.checkDuplicateId(idNumber, existingId: existingId);
      if (duplicate) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ID Number already exists.")),
        );
        setState(() => _saving = false);
        return;
      }

      // Boolean mapping
      final disabilityBool = _selectedDisability == "True";

      final data = {
        "IP_Name": _selectedIpName,
        "Sector": _selectedSector,
        "Name": _nameCtrl.text.trim(),
        "ID_Number": idNumber,
        "Indicator": _indicatorCtrl.text.trim(),
        "Date": _dateCtrl.text.isEmpty ? null : _dateCtrl.text,
        "Parent_ID": _parentIdCtrl.text.isEmpty ? null : _parentIdCtrl.text,
        "Spouse_ID": _spouseIdCtrl.text.isEmpty ? null : _spouseIdCtrl.text,
        "Phone_Number": _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
        "Date_of_Birth": _dobCtrl.text.isEmpty ? null : _dobCtrl.text,
        "Age": _ageCtrl.text.isEmpty ? null : _ageCtrl.text,
        "Gender": _selectedGender,
        "Governorate": _govCtrl.text.isEmpty ? null : _govCtrl.text,
        "Municipality": _munCtrl.text.isEmpty ? null : _munCtrl.text,
        "Neighborhood": _neighCtrl.text.isEmpty ? null : _neighCtrl.text,
        "Site_Name": _siteCtrl.text.isEmpty ? null : _siteCtrl.text,
        "Disability_Status": disabilityBool,
        "created_by": widget.beneficiary?.createdBy ?? username,
        "Submission_Time": widget.beneficiary?.submissionTime ?? nowIso,
        "Household_ID":
            _householdCtrl.text.isEmpty ? null : _householdCtrl.text,
      };

      if (_isEdit) {
        await _api.updateBeneficiary(widget.beneficiary!.id!, data);
      } else {
        await _api.createBeneficiary(data);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? "Updated" : "Created")),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? "Edit Beneficiary" : "Add Beneficiary";

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _loadingDropdowns
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedIpName,
                              decoration:
                                  const InputDecoration(labelText: "IP Name *"),
                              items: _ipOptions
                                  .map((v) => DropdownMenuItem(
                                      value: v, child: Text(v)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedIpName = v),
                              validator: (v) => v == null ? "Required" : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSector,
                              decoration:
                                  const InputDecoration(labelText: "Sector *"),
                              items: _sectorOptions
                                  .map((v) => DropdownMenuItem(
                                      value: v, child: Text(v)))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedSector = v),
                              validator: (v) => v == null ? "Required" : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: "Name *"),
                        validator: (v) => v!.trim().isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _idNumberCtrl,
                        decoration:
                            const InputDecoration(labelText: "ID Number *"),
                        validator: (v) => v!.trim().isEmpty ? "Required" : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _indicatorCtrl,
                        decoration:
                            const InputDecoration(labelText: "Indicator"),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Date",
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () => _pickDate(_dateCtrl),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _parentIdCtrl,
                        decoration:
                            const InputDecoration(labelText: "Parent ID"),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _spouseIdCtrl,
                        decoration:
                            const InputDecoration(labelText: "Spouse ID"),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration:
                            const InputDecoration(labelText: "Phone Number"),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dobCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: "Date of Birth",
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () => _pickDate(_dobCtrl),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ageCtrl,
                        decoration: const InputDecoration(labelText: "Age"),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(labelText: "Gender"),
                        items: const [
                          DropdownMenuItem(value: "Male", child: Text("Male")),
                          DropdownMenuItem(
                              value: "Female", child: Text("Female")),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _govCtrl,
                        decoration:
                            const InputDecoration(labelText: "Governorate"),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _munCtrl,
                        decoration:
                            const InputDecoration(labelText: "Municipality"),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _neighCtrl,
                        decoration:
                            const InputDecoration(labelText: "Neighborhood"),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _siteCtrl,
                        decoration:
                            const InputDecoration(labelText: "Site Name"),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedDisability,
                        decoration: const InputDecoration(
                            labelText: "Disability Status"),
                        items: const [
                          DropdownMenuItem(value: "True", child: Text("True")),
                          DropdownMenuItem(
                              value: "False", child: Text("False")),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedDisability = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _householdCtrl,
                        decoration:
                            const InputDecoration(labelText: "Household ID"),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save),
                          label:
                              Text(_isEdit ? "Save Changes" : "Create Record"),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
