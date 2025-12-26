import 'package:flutter/material.dart';

import '../models/beneficiary.dart';
import '../offline/dropdown_loader.dart';
import '../offline/pending_queue.dart';
import '../services/token_service.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BeneficiaryFormScreen extends StatefulWidget {
  final Beneficiary? beneficiary;

  const BeneficiaryFormScreen({super.key, this.beneficiary});

  @override
  State<BeneficiaryFormScreen> createState() => _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState extends State<BeneficiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();

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
  final _governorateCtrl = TextEditingController();
  final _municipalityCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _siteNameCtrl = TextEditingController();
  final _householdIdCtrl = TextEditingController();

  List<String> _ipOptions = [];
  List<String> _sectorOptions = [];

  String? _selectedIpName;
  String? _selectedSector;
  String? _selectedGender;
  String? _selectedDisability; // 'True' or 'False'

  bool _loadingDropdowns = true;
  bool _saving = false;

  bool get _isEdit => widget.beneficiary != null;

  @override
  void initState() {
    super.initState();
    _initFromBeneficiary();
    _loadDropdowns();
  }

  void _initFromBeneficiary() {
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
    _governorateCtrl.text = b.governorate ?? '';
    _municipalityCtrl.text = b.municipality ?? '';
    _neighborhoodCtrl.text = b.neighborhood ?? '';
    _siteNameCtrl.text = b.siteName ?? '';
    _selectedDisability = b.disabilityStatus;
    _householdIdCtrl.text = b.householdId ?? '';
  }

  Future<void> _loadDropdowns() async {
    final loader = DropdownLoader();
    final data = await loader.loadIpNamesAndSectors();
    setState(() {
      _ipOptions = data['ip_names'] ?? [];
      _sectorOptions = data['sectors'] ?? [];

      if (_selectedIpName != null &&
          _selectedIpName!.isNotEmpty &&
          !_ipOptions.contains(_selectedIpName)) {
        _ipOptions.insert(0, _selectedIpName!);
      }
      if (_selectedSector != null &&
          _selectedSector!.isNotEmpty &&
          !_sectorOptions.contains(_selectedSector)) {
        _sectorOptions.insert(0, _selectedSector!);
      }

      _loadingDropdowns = false;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idNumberCtrl.dispose();
    _indicatorCtrl.dispose();
    _dateCtrl.dispose();
    _parentIdCtrl.dispose();
    _spouseIdCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _ageCtrl.dispose();
    _governorateCtrl.dispose();
    _municipalityCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _siteNameCtrl.dispose();
    _householdIdCtrl.dispose();
    super.dispose();
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
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<bool> _localDuplicateExists(
      String idNumber, Beneficiary? current) async {
    final box = Hive.box('beneficiaries');
    for (final dynamic key in box.keys) {
      final map =
          Map<String, dynamic>.from(box.get(key, defaultValue: {}) as Map);
      final b = Beneficiary.fromMap(map);
      if (b.idNumber?.trim() == idNumber.trim()) {
        if (current != null && b.id == current.id) continue;
        return true;
      }
    }
    return false;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIpName == null || _selectedSector == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IP Name and Sector are required.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final username = await TokenService.getUsername() ?? '';
      final nowIso = DateTime.now().toIso8601String();

      final idNumber = _idNumberCtrl.text.trim();
      final current = widget.beneficiary;

      // Local duplicate check
      final localDup = await _localDuplicateExists(idNumber, current);
      if (localDup) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ID Number already exists locally.'),
            ),
          );
        }
        return;
      }

      final newB = Beneficiary(
        id: current?.id,
        recordId: current?.recordId,
        inFormId: current?.inFormId,
        instanceId: current?.instanceId,
        ipName: _selectedIpName,
        sector: _selectedSector,
        indicator: _indicatorCtrl.text.trim().isEmpty
            ? null
            : _indicatorCtrl.text.trim(),
        date: _dateCtrl.text.trim().isEmpty ? null : _dateCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        idNumber: idNumber,
        parentId: _parentIdCtrl.text.trim().isEmpty
            ? null
            : _parentIdCtrl.text.trim(),
        spouseId: _spouseIdCtrl.text.trim().isEmpty
            ? null
            : _spouseIdCtrl.text.trim(),
        phoneNumber:
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        dateOfBirth: _dobCtrl.text.trim().isEmpty ? null : _dobCtrl.text.trim(),
        age: _ageCtrl.text.trim().isEmpty ? null : _ageCtrl.text.trim(),
        gender: _selectedGender,
        governorate: _governorateCtrl.text.trim().isEmpty
            ? null
            : _governorateCtrl.text.trim(),
        municipality: _municipalityCtrl.text.trim().isEmpty
            ? null
            : _municipalityCtrl.text.trim(),
        neighborhood: _neighborhoodCtrl.text.trim().isEmpty
            ? null
            : _neighborhoodCtrl.text.trim(),
        siteName: _siteNameCtrl.text.trim().isEmpty
            ? null
            : _siteNameCtrl.text.trim(),
        disabilityStatus: _selectedDisability,
        createdAt: current?.createdAt ?? nowIso,
        createdBy: current?.createdBy ?? username,
        submissionTime: current?.submissionTime ?? nowIso,
        deleted: current?.deleted ?? false,
        deletedAt: current?.deletedAt,
        undeletedAt: current?.undeletedAt,
        householdId: _householdIdCtrl.text.trim().isEmpty
            ? null
            : _householdIdCtrl.text.trim(),
        synced: _isEdit ? 'update' : 'no',
      );

      final box = Hive.box('beneficiaries');
      int hiveKey;
      if (_isEdit) {
        // find existing hive key by matching idNumber + created_by
        dynamic foundKey;
        for (final dynamic key in box.keys) {
          final map =
              Map<String, dynamic>.from(box.get(key, defaultValue: {}) as Map);
          final b = Beneficiary.fromMap(map);
          if (b.idNumber == current!.idNumber &&
              (b.createdBy ?? '') == (current.createdBy ?? '')) {
            foundKey = key;
            break;
          }
        }
        if (foundKey != null) {
          hiveKey = foundKey as int;
          await box.put(hiveKey, newB.toMap());
          await PendingQueue.enqueueUpdate(hiveKey, newB);
        } else {
          hiveKey = await box.add(newB.toMap());
          await PendingQueue.enqueueUpdate(hiveKey, newB);
        }
      } else {
        hiveKey = await box.add(newB.toMap());
        await PendingQueue.enqueueCreate(hiveKey, newB);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isEdit ? 'Beneficiary updated (offline)' : 'Beneficiary added'),
        ),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit Beneficiary' : 'Add Beneficiary';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _loadingDropdowns
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                  const InputDecoration(labelText: 'IP Name *'),
                              items: _ipOptions
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _selectedIpName = v;
                              }),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSector,
                              decoration:
                                  const InputDecoration(labelText: 'Sector *'),
                              items: _sectorOptions
                                  .map(
                                    (v) => DropdownMenuItem(
                                      value: v,
                                      child: Text(v),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() {
                                _selectedSector = v;
                              }),
                              validator: (v) =>
                                  v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name *'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _idNumberCtrl,
                        decoration:
                            const InputDecoration(labelText: 'ID Number *'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _indicatorCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Indicator'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dateCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () => _pickDate(_dateCtrl),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _parentIdCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Parent ID'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _spouseIdCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Spouse ID'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Phone Number'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _dobCtrl,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () => _pickDate(_dobCtrl),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _ageCtrl,
                        decoration: const InputDecoration(labelText: 'Age'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Male',
                            child: Text('Male'),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _selectedGender = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _governorateCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Governorate'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _municipalityCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Municipality'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _neighborhoodCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Neighborhood'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _siteNameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Site Name'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedDisability,
                        decoration: const InputDecoration(
                            labelText: 'Disability Status'),
                        items: const [
                          DropdownMenuItem(
                            value: 'True',
                            child: Text('True'),
                          ),
                          DropdownMenuItem(
                            value: 'False',
                            child: Text('False'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedDisability = v),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _householdIdCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Household ID'),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label:
                              Text(_isEdit ? 'Save changes' : 'Create record'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
