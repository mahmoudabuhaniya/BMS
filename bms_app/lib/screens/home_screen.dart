import 'package:flutter/material.dart';
import '../services/token_service.dart';
import 'beneficiary_list_screen.dart';
import 'beneficiary_form_screen.dart';
import 'deleted_beneficiary_list_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String username = "";
  List<String> groups = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    username = await TokenService.getUsername() ?? "";
    groups = await TokenService.getGroups();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF1E88E5);

    return Scaffold(
      appBar: AppBar(
        title: const Text("BMS Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await TokenService.clearAll();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, $username",
                style:
                    const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            Text("Groups: ${groups.join(", ")}",
                style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 40),
            _menuButton(
              label: "➕ Add Beneficiary",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const BeneficiaryFormScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _menuButton(
              label: "📋 All Beneficiaries",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const BeneficiaryListScreen(showDeleted: false)),
              ),
            ),
            const SizedBox(height: 12),
            _menuButton(
              label: "🗑 Deleted Beneficiaries",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const DeletedBeneficiaryListScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
