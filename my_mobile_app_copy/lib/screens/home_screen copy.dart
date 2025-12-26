import 'package:flutter/material.dart';
import '../services/token_service.dart';
import '../services/dropdown_service.dart';
import 'beneficiary_form.dart';
import 'beneficiary_list.dart';
import '../offline/dropdown_loader.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> ipNames = [];
  List<String> sectors = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
  }

  Future<void> _loadDropdowns() async {
    final dropdowns = await DropdownService.loadDropdowns();
    setState(() {
      ipNames = dropdowns["ip_names"] ?? [];
      sectors = dropdowns["sectors"] ?? [];
      loading = false;
    });
  }

  Future<void> _logout() async {
    await TokenService.clearToken();
    await TokenService.clearUserInfo();

    if (mounted) {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _menuTile(
            title: "Add New Beneficiary",
            icon: Icons.person_add,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FutureBuilder(
                    future: DropdownLoader.loadDistinctValues(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());

                      final data = snapshot.data as Map<String, List<String>>;

                      return BeneficiaryFormScreen(
                        ipNames: data["ip_names"]!,
                        sectors: data["sectors"]!,
                      );
                    },
                  ),
                ),
              );
            },
          ),
          _menuTile(
            title: "View Beneficiaries",
            icon: Icons.list_alt,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BeneficiaryListScreen(
                    ipNames: ipNames,
                    sectors: sectors,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, size: 32, color: Colors.blue.shade700),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
