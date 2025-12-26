import 'package:flutter/material.dart';

import '../services/token_service.dart';
import '../services/api_service.dart';
import 'beneficiary_list.dart';
import 'beneficiary_form.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = '';
  List<String> _groups = [];
  bool _loadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final username = await TokenService.getUsername() ?? '';
    final groups = await TokenService.getGroups();

    setState(() {
      _username = username;
      _groups = groups;
      _loadingUser = false;
    });
  }

  Future<void> _logout() async {
    await TokenService.clearAll();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final primaryGroup = _groups.isNotEmpty ? _groups.first : 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Beneficiary Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SafeArea(
        child: _loadingUser
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $_username',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Group: $primaryGroup',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _HomeCard(
                            icon: Icons.people,
                            title: 'Beneficiaries',
                            subtitle: 'View active records',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BeneficiaryListScreen(
                                    showDeleted: false,
                                  ),
                                ),
                              );
                            },
                          ),
                          _HomeCard(
                            icon: Icons.delete,
                            title: 'Deleted',
                            subtitle: 'View deleted records',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BeneficiaryListScreen(
                                    showDeleted: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          _HomeCard(
                            icon: Icons.person_add,
                            title: 'Add Beneficiary',
                            subtitle: 'Create new record',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const BeneficiaryFormScreen(),
                                ),
                              );
                            },
                          ),
                          _HomeCard(
                            icon: Icons.sync,
                            title: 'Sync',
                            subtitle: 'Offline sync (coming soon)',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Sync will be implemented soon.'),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
