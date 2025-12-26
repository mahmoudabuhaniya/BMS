import 'package:flutter/material.dart';
import '../models/beneficiary.dart';
import '../services/token_service.dart';
import '../services/api_service.dart';

class BeneficiaryFormScreen extends StatefulWidget {
  final Beneficiary? beneficiary;
  final List<String> ipNames;
  final List<String> sectors;

  const BeneficiaryFormScreen({
    super.key,
    this.beneficiary,
    required this.ipNames,
    required this.sectors,
  });

  @override
  State<BeneficiaryFormScreen> createState() => _BeneficiaryFormScreenState();
}

class _BeneficiaryFormScreenState extends State<BeneficiaryFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _ipName = TextEditingController();
  final TextEditingController _sector = TextEditingController();
  final TextEditingController _idNumber = TextEditingController();

  late bool isEdit;

  @override
  void initState() {
    super.initState();
    isEdit = widget.beneficiary != null;

    if (isEdit) {
      final b = widget.beneficiary!;
      _ipName.text = b.ipName ?? "";
      _sector.text = b.sector ?? "";
      _idNumber.text = b.idNumber ?? "";
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final username = await TokenService.getUsername();

    final data = {
      "ipname": _ipName.text.trim(),
      "sector": _sector.text.trim(),
      "id_number": _idNumber.text.trim(),
      "created_by": username,
    };

    await ApiService()
        .submitItem(data, existing: isEdit ? widget.beneficiary : null);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Beneficiary" : "New Beneficiary"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _dropdownField("IP Name", _ipName, widget.ipNames),
              _dropdownField("Sector", _sector, widget.sectors),
              TextFormField(
                controller: _idNumber,
                decoration: const InputDecoration(labelText: "ID Number"),
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _save,
                child: const Text("Save"),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownField(
      String label, TextEditingController ctrl, List<String> items) {
    return DropdownButtonFormField<String>(
      value: ctrl.text.isNotEmpty ? ctrl.text : null,
      decoration: InputDecoration(labelText: label),
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) => ctrl.text = v ?? "",
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    );
  }
}
