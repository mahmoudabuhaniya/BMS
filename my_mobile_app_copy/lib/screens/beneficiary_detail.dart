// lib/screens/beneficiary_detail.dart
import 'package:flutter/material.dart';

class BeneficiaryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> beneficiary;

  const BeneficiaryDetailScreen({super.key, required this.beneficiary});

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value ?? "-",
              style: const TextStyle(fontSize: 15, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1CABE2))),
          const Divider(color: Colors.black26),
          ...children
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const unicefBlue = Color(0xFF1CABE2);
    const backgroundColor = Color(0xFFE6F4FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: unicefBlue,
        title: const Text("Beneficiary Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSection("Personal Information", [
              _buildDetailRow("Name", beneficiary["name"]),
              _buildDetailRow("ID Number", beneficiary["idNumber"]),
              _buildDetailRow("Phone Number", beneficiary["phoneNumber"]),
              _buildDetailRow("Date of Birth", beneficiary["dateOfBirth"]),
              _buildDetailRow("Age", beneficiary["age"]?.toString()),
              _buildDetailRow("Gender", beneficiary["gender"]),
            ]),
            _buildSection("Location Information", [
              _buildDetailRow("Governorate", beneficiary["governorate"]),
              _buildDetailRow("Municipality", beneficiary["municipality"]),
              _buildDetailRow("Neighborhood", beneficiary["neighborhood"]),
              _buildDetailRow("Site Name", beneficiary["siteName"]),
            ]),
            _buildSection("Program Information", [
              _buildDetailRow("IP Name", beneficiary["ipName"]),
              _buildDetailRow("Sector", beneficiary["sector"]),
              _buildDetailRow("Indicator", beneficiary["Indicator"]),
              _buildDetailRow("Date", beneficiary["date"]),
              _buildDetailRow("Disability Status", beneficiary["disabilityStatus"]),
              _buildDetailRow("Submission Time", beneficiary["submissionTime"]),
            ]),
          ],
        ),
      ),
    );
  }
}
