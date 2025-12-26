import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/beneficiary.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../db/hive_manager.dart';
import '../utils/validators.dart';
import '../utils/helpers.dart';
import '../utils/date_utils.dart';
import 'package:uuid/uuid.dart';

class BeneficiaryFormScreen extends StatefulWidget {
  final Beneficiary? beneficiary;

  const BeneficiaryFormScreen({super.key, this.beneficiary});

  @override
  State<BeneficiaryFormScreen> createState() => _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState extends State<BeneficiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameCtrl = TextEditingController();
  final idNumberCtrl = TextEditingController();
  final indicatorCtrl = TextEditingController();
  final dateCtrl = TextEditingController();
  final parentIdCtrl = TextEditingController();
  final spouseIdCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final dobCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final governorateCtrl = TextEditingController();
  final municipalityCtrl = TextEditingController();
  final neighborhoodCtrl = TextEditingController();
  final siteNameCtrl = TextEditingController();

  // Dropdown values
  String? ipName;
  String? sector;
  String? gender;
  String? disabilityStatus;

  // Lists
  List<String> ipNames = [];
  List<String> sectors = [];
  final List<String> genderList = ["M", "F"];
  final List<String> disabilityList = ["Yes", "No"];

  bool checkingDuplicate = false;
  bool isDuplicate = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _loadDropdowns();
  }

  // ---------------------------------------------------------------------------
  // SAFE MERGED LIST LOADING
  // ---------------------------------------------------------------------------
  Future<void> _loadDropdowns() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth);

    final remoteIp = await api.fetchDistinctIpNames();
    final remoteSec = await api.fetchDistinctSectors();

    // Start with remote lists
    final mergedIP = [...remoteIp];
    final mergedSec = [...remoteSec];

    // Ensure current beneficiary values are included
    if (widget.beneficiary?.ipName != null &&
        widget.beneficiary!.ipName!.trim().isNotEmpty &&
        !mergedIP.contains(widget.beneficiary!.ipName)) {
      mergedIP.add(widget.beneficiary!.ipName!);
    }

    if (widget.beneficiary?.sector != null &&
        widget.beneficiary!.sector!.trim().isNotEmpty &&
        !mergedSec.contains(widget.beneficiary!.sector)) {
      mergedSec.add(widget.beneficiary!.sector!);
    }

    setState(() {
      ipNames = mergedIP.toSet().toList()..sort();
      sectors = mergedSec.toSet().toList()..sort();
    });
  }

  // ---------------------------------------------------------------------------
  // LOAD EXISTING DATA (EDIT MODE)
  // ---------------------------------------------------------------------------
  void _loadExistingData() {
    if (widget.beneficiary == null) return;

    final b = widget.beneficiary!;

    nameCtrl.text = Helpers.nullToEmpty(b.name);
    idNumberCtrl.text = Helpers.nullToEmpty(b.idNumber);
    indicatorCtrl.text = Helpers.nullToEmpty(b.indicator);
    dateCtrl.text = Helpers.nullToEmpty(b.date);
    parentIdCtrl.text = Helpers.nullToEmpty(b.parentId);
    spouseIdCtrl.text = Helpers.nullToEmpty(b.spouseId);
    phoneCtrl.text = Helpers.nullToEmpty(b.phoneNumber);
    dobCtrl.text = Helpers.nullToEmpty(b.dateOfBirth);
    ageCtrl.text = Helpers.nullToEmpty(b.age?.toString());
    governorateCtrl.text = Helpers.nullToEmpty(b.governorate);
    municipalityCtrl.text = Helpers.nullToEmpty(b.municipality);
    neighborhoodCtrl.text = Helpers.nullToEmpty(b.neighborhood);
    siteNameCtrl.text = Helpers.nullToEmpty(b.siteName);

    ipName = b.ipName;
    sector = b.sector;
    gender = b.gender;
    disabilityStatus = b.disabilityStatus;
  }

  // ---------------------------------------------------------------------------
  // DUPLICATE CHECK
  // ---------------------------------------------------------------------------
  Future<void> checkDuplicate() async {
    setState(() => checkingDuplicate = true);

    final idNum = idNumberCtrl.text.trim();

    // Check local duplicates
    final existsLocal = HiveManager.beneficiaries.values.any((b) =>
        b.idNumber != null &&
        b.idNumber!.trim() == idNum &&
        b.id != widget.beneficiary?.id);

    if (existsLocal) {
      setState(() {
        checkingDuplicate = false;
        isDuplicate = true;
      });
      return;
    }

    // Check remote
    final auth = Provider.of<AuthService>(context, listen: false);
    final api = ApiService(auth);

    final remote = await api.checkDuplicateID(idNum);

    setState(() {
      checkingDuplicate = false;
      isDuplicate = remote;
    });
  }

  // ---------------------------------------------------------------------------
  // DATE PICKER
  // ---------------------------------------------------------------------------
  Future<void> pickDate(TextEditingController ctrl) async {
    final initial = DateUtilsHelper.parse(ctrl.text) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      ctrl.text = DateFormat("yyyy-MM-dd").format(picked);
    }
  }

  // ---------------------------------------------------------------------------
  // SAVE RECORD
  // ---------------------------------------------------------------------------
  Future<void> saveBeneficiary() async {
    if (!_formKey.currentState!.validate()) return;
    if (isDuplicate) return;

    final auth = Provider.of<AuthService>(context, listen: false);

    // inside saveBeneficiary()

    final uuid = const Uuid().v4();

    Beneficiary b = widget.beneficiary ??
        Beneficiary(
          createdBy: auth.currentUser?.username ?? "",
          deleted: false,
          synced: "no",
        );

    b.name = nameCtrl.text.trim();
    b.idNumber = idNumberCtrl.text.trim();
    b.indicator = indicatorCtrl.text.trim();
    b.date = Helpers.emptyToNull(dateCtrl.text);
    b.parentId = Helpers.emptyToNull(parentIdCtrl.text);
    b.spouseId = Helpers.emptyToNull(spouseIdCtrl.text);
    b.phoneNumber = Helpers.emptyToNull(phoneCtrl.text);
    b.dateOfBirth = Helpers.emptyToNull(dobCtrl.text);
    b.governorate = Helpers.emptyToNull(governorateCtrl.text);
    b.municipality = Helpers.emptyToNull(municipalityCtrl.text);
    b.neighborhood = Helpers.emptyToNull(neighborhoodCtrl.text);
    b.siteName = Helpers.emptyToNull(siteNameCtrl.text);

    b.ipName = ipName;
    b.sector = sector;
    b.gender = gender;
    b.disabilityStatus = disabilityStatus;

    if (widget.beneficiary == null) {
      b.synced = "no";
      await HiveManager.beneficiaries.add(b);

      await HiveManager.addToQueue({
        "action": "create",
        "id": b.id,
        "payload": b.toJson(),
      });
    } else {
      b.synced = "update";
      await b.save();

      await HiveManager.addToQueue({
        "action": "update",
        "id": b.id,
        "payload": b.toJson(),
      });
    }

    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.beneficiary == null
            ? "Add Beneficiary"
            : "Edit Beneficiary"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _section("Project Information"),
              _smartDropdown(
                "IP Name *",
                ipNames,
                ipName,
                (v) => setState(() => ipName = v),
                validator: Validators.required,
              ),
              const SizedBox(height: 12),
              _smartDropdown(
                "Sector *",
                sectors,
                sector,
                (v) => setState(() => sector = v),
                validator: Validators.required,
              ),
              const SizedBox(height: 20),
              _section("Personal Information"),
              _input("Name *", nameCtrl, validator: Validators.required),
              const SizedBox(height: 12),
              _input("ID Number *", idNumberCtrl,
                  validator: Validators.idNumber,
                  onChanged: (_) => checkDuplicate()),
              if (checkingDuplicate)
                const Text("Checking duplicate…",
                    style: TextStyle(color: Colors.orange)),
              if (isDuplicate)
                const Text("Duplicate ID!",
                    style: TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              _input("Phone Number", phoneCtrl),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => pickDate(dobCtrl),
                child: AbsorbPointer(child: _input("Date of Birth", dobCtrl)),
              ),
              const SizedBox(height: 12),
              _dropdown("Gender", genderList, gender,
                  (v) => setState(() => gender = v)),
              const SizedBox(height: 20),
              _section("Household"),
              _input("Parent ID", parentIdCtrl),
              const SizedBox(height: 12),
              _input("Spouse ID", spouseIdCtrl),
              const SizedBox(height: 20),
              _section("Location"),
              _input("Governorate", governorateCtrl),
              const SizedBox(height: 12),
              _input("Municipality", municipalityCtrl),
              const SizedBox(height: 12),
              _input("Neighborhood", neighborhoodCtrl),
              const SizedBox(height: 12),
              _input("Site Name", siteNameCtrl),
              const SizedBox(height: 20),
              _section("Additional Information"),
              _input("Indicator", indicatorCtrl),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => pickDate(dateCtrl),
                child: AbsorbPointer(child: _input("Date", dateCtrl)),
              ),
              const SizedBox(height: 12),
              _dropdown(
                "Disability Status",
                disabilityList,
                disabilityStatus,
                (v) => setState(() => disabilityStatus = v),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save"),
                onPressed: saveBeneficiary,
              ),
              ElevatedButton(
                onPressed: () async {
                  await HiveManager.clearAll();
                  print("Hive cleared");
                },
                child: Text("Clear Hive"),
              )
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widget helpers
  // ---------------------------------------------------------------------------
  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1CABE2),
        ),
      ),
    );
  }

  Widget _input(String label, TextEditingController ctrl,
      {String? Function(String?)? validator, Function(String)? onChanged}) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }

  // Smart dropdown → allows text input when list is empty
  Widget _smartDropdown(String label, List<String> items, String? value,
      Function(String?) onChanged,
      {String? Function(String?)? validator}) {
    if (items.isEmpty) {
      return TextFormField(
        initialValue: value,
        decoration: InputDecoration(labelText: "$label (manual)"),
        onChanged: onChanged,
        validator: validator,
      );
    }

    // Allow null selection only if value is null OR in items
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      items:
          items.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }

  Widget _dropdown(String label, List<String> items, String? value,
      Function(String?) onChanged,
      {String? Function(String?)? validator}) {
    return DropdownButtonFormField<String>(
      value: items.contains(value) ? value : null,
      items:
          items.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }
}
