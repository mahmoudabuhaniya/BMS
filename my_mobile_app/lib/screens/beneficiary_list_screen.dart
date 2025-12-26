import 'package:bms_offline_app/offline/beneficiary_repository.dart';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/beneficiary.dart';
import '../services/token_service.dart';
import '../widgets/offline_badge.dart';
import 'beneficiary_form_screen.dart';

class BeneficiaryListScreen extends StatefulWidget {
  final bool showDeleted;

  const BeneficiaryListScreen({super.key, required this.showDeleted});

  @override
  State<BeneficiaryListScreen> createState() => _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends State<BeneficiaryListScreen> {
  List<Beneficiary> _items = [];
  List<Beneficiary> _filtered = [];
  String _search = '';
  String _username = '';
  List<String> _groups = [];
  bool _loading = true;

  bool _isAdminOrManagerGroups(List<String> groups) {
    return groups.contains('Admin') || groups.contains('Manager');
  }

  bool _isAdminOrManager(List<String> groups) {
    return groups.contains("Admin") ||
        groups.contains("Manager") ||
        groups.contains("Superuser");
  }

  @override
  void initState() {
    super.initState();

    fetchBeneficiaries(); // 👈 Load immediately on screen open
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final username = await TokenService.getUsername() ?? '';
    final groups = await TokenService.getGroups();

    final box = Hive.box('beneficiaries');
    final items = <Beneficiary>[];

    for (final dynamic key in box.keys) {
      final map =
          Map<String, dynamic>.from(box.get(key, defaultValue: {}) as Map);
      final b = Beneficiary.fromMap(map);

      if (widget.showDeleted) {
        if (!b.deleted) continue;
      } else {
        if (b.deleted) continue;
      }

      if (_isAdminOrManagerGroups(groups)) {
        items.add(b);
      } else {
        if (b.createdBy == username) {
          items.add(b);
        }
      }
    }

    setState(() {
      _username = username;
      _groups = groups;
      _items = items;
      _applyFilter();
      _loading = false;
    });
  }

  void _applyFilter() {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = List.of(_items);
    } else {
      _filtered = _items.where((b) {
        bool match = false;
        if ((b.name ?? '').toLowerCase().contains(q)) match = true;
        if ((b.idNumber ?? '').toLowerCase().contains(q)) match = true;
        if ((b.ipName ?? '').toLowerCase().contains(q)) match = true;
        if ((b.sector ?? '').toLowerCase().contains(q)) match = true;
        return match;
      }).toList();
    }
  }

  Future<void> _onRefresh() async {
    await _load();
    await fetchBeneficiaries(); // 👈 Reload manually
  }

  void _onSearch(String value) {
    setState(() {
      _search = value;
      _applyFilter();
    });
  }

  Future<void> fetchBeneficiaries() async {
    setState(() => _loading = true);

    try {
      final all = await BeneficiaryRepository.getAll(
        showDeleted: widget.showDeleted,
        username: _username,
        isAdmin: _isAdminOrManager(_groups),
      );

      setState(() {
        _items = all;
      });
    } catch (e) {
      debugPrint("Error loading beneficiaries: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.showDeleted ? 'Deleted Beneficiaries' : 'Beneficiaries';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search by name, ID, IP Name or sector',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: _onSearch,
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: _filtered.isEmpty
                          ? ListView(
                              children: const [
                                SizedBox(height: 80),
                                Center(child: Text('No records found')),
                              ],
                            )
                          : ListView.builder(
                              itemCount: _filtered.length,
                              itemBuilder: (context, index) {
                                final b = _filtered[index];
                                return Card(
                                  child: ListTile(
                                    leading: OfflineBadge(synced: b.synced),
                                    title: Text(b.name ?? '-'),
                                    subtitle: Text(
                                      'ID: ${b.idNumber ?? '-'}\n'
                                      'IP: ${b.ipName ?? '-'} | Sector: ${b.sector ?? '-'}',
                                    ),
                                    isThreeLine: true,
                                    onTap: () async {
                                      final updated =
                                          await Navigator.of(context)
                                              .push<bool>(
                                        MaterialPageRoute(
                                          builder: (_) => BeneficiaryFormScreen(
                                            beneficiary: b,
                                          ),
                                        ),
                                      );
                                      if (updated == true) {
                                        await _load();
                                      }
                                    },
                                  ),
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
