// lib/features/proses_produksi/view/proses_produksi_menu_screen.dart
import 'package:flutter/material.dart';

import '../../../core/services/permission_storage.dart';
import '../../home/widget/dashboard_widgets.dart';
import '../model/proses_produksi_process.dart';
import 'proses_produksi_list_screen.dart';

/// Menu "Proses Produksi" berisi 7 sub-menu:
/// S4S, Finger Joint, Moulding, Laminating, Cross Cut, Sanding, Barang Jadi.
class ProsesProduksiMenuScreen extends StatefulWidget {
  const ProsesProduksiMenuScreen({super.key});

  @override
  State<ProsesProduksiMenuScreen> createState() =>
      _ProsesProduksiMenuScreenState();
}

class _ProsesProduksiMenuScreenState extends State<ProsesProduksiMenuScreen> {
  Set<String>? _permissions; // null = masih load

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final list = await PermissionStorage.getPermissions();
    if (!mounted) return;
    setState(() => _permissions = list.toSet());
  }

  bool _can(String code) => _permissions?.contains(code) ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Proses Produksi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: kProsesProduksiBrand,
        elevation: 0,
      ),
      body: _permissions == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: kProsesProduksiBrand,
              onRefresh: _loadPermissions,
              child: GridView.count(
                crossAxisCount: 2,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
                children: [
                  for (final p in prosesProduksiProcesses)
                    DashboardModuleTile(
                      icon: p.icon,
                      title: p.title,
                      subtitle: p.description,
                      allowed: _can(p.permission),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProsesProduksiListScreen(process: p),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
