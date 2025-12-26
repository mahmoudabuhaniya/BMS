import 'package:flutter/material.dart';
import '../models/beneficiary.dart';
import 'beneficiary_form_screen.dart';

class BeneficiaryDetailScreen extends StatelessWidget {
  final Beneficiary beneficiary;

  const BeneficiaryDetailScreen({super.key, required this.beneficiary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(beneficiary.name ?? "Details")),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: ListView(
          children: [
            Text("ID Number: ${beneficiary.idNumber ?? ""}"),
            Text("Sector: ${beneficiary.sector ?? ""}"),
            Text("Governorate: ${beneficiary.governorate ?? ""}"),
            Text("Phone: ${beneficiary.phoneNumber ?? ""}"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text("Edit"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        BeneficiaryFormScreen(beneficiary: beneficiary),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
