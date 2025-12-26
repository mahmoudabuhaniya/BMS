import 'package:flutter/material.dart';

import '../services/token_service.dart';
import '../offline/sync_service.dart';
import 'beneficiary_list_screen.dart';
import 'beneficiary_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = '';
  List<String> _groups = [];
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final name = await TokenService.getUsername() ?? '';
    final groups = await TokenService.getGroups();
    if (!mounted) return;
    setState(() {
      _username = name;
      _groups = groups;
    });
  }

  String get _mainGroup {
    if (_groups.isEmpty) return 'User';
    return _groups.first;
  }

  Future<void> _logout() async {
    await TokenService.clearAll();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _runSync() async {
    setState(() => _syncing = true);
    try {
      await SyncService.processQueue();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync finished')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final greetingName = _username.isEmpty ? 'Guest' : _username;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiary Home'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مرحبا، $greetingName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Group: $_mainGroup',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'You can add, view and manage beneficiaries, even when you are offline. Changes will sync when internet is available.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _HomeButton(
              icon: Icons.person_add_alt_1,
              title: 'Add New Beneficiary',
              subtitle: 'Create a new record',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BeneficiaryFormScreen(),
                  ),
                );
              },
            ),
            _HomeButton(
              icon: Icons.list_alt,
              title: 'All Beneficiaries',
              subtitle: 'Browse and search records',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const BeneficiaryListScreen(showDeleted: false),
                  ),
                );
              },
            ),
            _HomeButton(
              icon: Icons.delete_outline,
              title: 'Deleted Beneficiaries',
              subtitle: 'Soft deleted records',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const BeneficiaryListScreen(showDeleted: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _syncing ? null : _runSync,
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync),
              label: Text(_syncing ? 'Syncing...' : 'Sync now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
