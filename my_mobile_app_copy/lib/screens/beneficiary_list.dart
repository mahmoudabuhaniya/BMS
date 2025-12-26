import 'package:flutter/material.dart';

import '../models/beneficiary.dart';
import '../services/api_service.dart';
import '../services/token_service.dart';
import 'beneficiary_form.dart';

class BeneficiaryListScreen extends StatefulWidget {
  final bool showDeleted;

  const BeneficiaryListScreen({super.key, required this.showDeleted});

  @override
  State<BeneficiaryListScreen> createState() => _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends State<BeneficiaryListScreen> {
  final ApiService _api = ApiService();
  List<Beneficiary> _items = [];
  bool _loading = true;
  String _search = '';
  String _username = '';
  List<String> _groups = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final username = await TokenService.getUsername() ?? '';
    final groups = await TokenService.getGroups();

    _username = username;
    _groups = groups;
    await _loadData();
  }

  bool get _isAdminLike =>
      _groups.contains('Admin') || _groups.contains('Manager');

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final apiItems =
          await _api.fetchBeneficiaries(showDeleted: widget.showDeleted);

      // Apply group filtering
      final filtered = _isAdminLike
          ? apiItems
          : apiItems
              .where((b) =>
                  (b.createdBy ?? '').toLowerCase() == _username.toLowerCase())
              .toList();

      setState(() {
        _items = filtered;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Beneficiary> get _filteredBySearch {
    if (_search.trim().isEmpty) return _items;
    final q = _search.trim().toLowerCase();
    return _items.where((b) {
      final name = (b.name ?? '').toLowerCase();
      final idn = (b.idNumber ?? '').toLowerCase();
      return name.contains(q) || idn.contains(q);
    }).toList();
  }

  Future<void> _onRefresh() async => _loadData();

  void _openEdit(Beneficiary b) {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => BeneficiaryFormScreen(beneficiary: b),
      ),
    )
        .then((changed) {
      if (changed == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.showDeleted ? 'Deleted beneficiaries' : 'Beneficiaries';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search by name or ID number',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _search = value;
                  });
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: _filteredBySearch.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(child: Text('No records found')),
                              ],
                            )
                          : ListView.builder(
                              itemCount: _filteredBySearch.length,
                              itemBuilder: (context, index) {
                                final b = _filteredBySearch[index];
                                final name = b.name ?? '(No name)';
                                final idn = b.idNumber ?? '-';

                                final syncedFlag =
                                    (b.synced ?? '').toLowerCase() == 'yes';

                                return ListTile(
                                  leading: Icon(
                                    syncedFlag
                                        ? Icons.cloud_done
                                        : Icons.cloud_off,
                                  ),
                                  title: Text(name),
                                  subtitle: Text('ID: $idn'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => _openEdit(b),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
