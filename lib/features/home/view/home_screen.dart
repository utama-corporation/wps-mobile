import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/permission_storage.dart';
import '../view_model/dashboard_summary_view_model.dart';
import '../widget/dashboard_widgets.dart';
import '../widget/user_profile_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Set<String>? _permissions; // null = loading
  static const _deniedMsg = 'Anda tidak punya akses';

  // Bottom nav state
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final list = await PermissionStorage.getPermissions();
    if (!mounted) return;
    setState(() => _permissions = list.toSet());
    _loadSummary();
  }

  bool _can(String code) => _permissions?.contains(code) ?? false;

  void _loadSummary() {
    if (!mounted) return;
    final canMapping = _can('mapping:read');
    final canQc = _can('spk:read');
    if (!canMapping && !canQc) return;
    context
        .read<DashboardSummaryViewModel>()
        .load(mapping: canMapping, qc: canQc);
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static const _dayNames = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];
  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi';
    if (h < 15) return 'Selamat siang';
    if (h < 18) return 'Selamat sore';
    return 'Selamat malam';
  }

  String _todayLabel() {
    final n = DateTime.now();
    return '${_dayNames[n.weekday - 1]}, ${n.day} ${_monthNames[n.month - 1]} ${n.year}';
  }

  // (opsional) logout
  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await PermissionStorage.clear();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const UserProfileDialog());
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _permissions == null;
    final brand = const Color(0xFF755330);

    return WillPopScope(
      onWillPop: () async {
        final ok = await _showExitDialog(context);
        return ok ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Dashboard',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: brand,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => _logout(context),
            ),
          ],
        ),

        // === BODY: IndexedStack agar state tiap tab tidak ter-reset ===
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                _buildBerandaTab(context), // 0
                _buildMappingTab(context), // 1
                _buildAkunTab(context), // 2
              ],
            ),

            // Veil loading saat permissions belum siap
            if (isLoading)
              Container(
                color: Colors.white.withOpacity(0.6),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),

        // === Navigation Bar (Material 3) ===
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          indicatorColor: brand.withOpacity(.12),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Mapping',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }

  // =================== TAB: BERANDA ===================
  Widget _buildBerandaTab(BuildContext context) {
    return Container(
      color: kCanvas,
      child: Consumer<DashboardSummaryViewModel>(
        builder: (context, vm, _) {
          return RefreshIndicator(
            color: kBrand,
            onRefresh: () => context.read<DashboardSummaryViewModel>().refresh(
                  mapping: _can('mapping:read'),
                  qc: _can('spk:read'),
                ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                _buildHeroPanel(context, vm),
                const SizedBox(height: 28),
                if (_can('mapping:read')) ...[
                  _buildMappingRingkasan(context, vm),
                  const SizedBox(height: 28),
                ],
                _sectionLabel('Menu'),
                const SizedBox(height: 12),
                _buildModuleGrid(context),
                if (vm.lastUpdated != null) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Diperbarui ${_hhmm(vm.lastUpdated!)} · tarik untuk memperbarui',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // =================== TAB: MAPPING ===================
  Widget _buildMappingTab(BuildContext context) {
    final allowed = _can('mapping:read');
    return _tabScaffold(
      title: 'Mapping',
      description: 'Kelola posisi / layout kayu.',
      primary: _primaryAction(
        context,
        label: 'Buka Mapping',
        icon: Icons.map,
        onTap: allowed ? () => Navigator.pushNamed(context, '/mapping') : null,
        disabledTooltip: !allowed ? _deniedMsg : null,
      ),
      extras: [
        _quickCard(
          context,
          title: 'Bongkar KD',
          subtitle: 'Kelola posisi setelah KD',
          icon: Icons.warehouse_outlined,
          color: const Color(0xFF755330),
          onTap: _can('bongkar_kd:read')
              ? () => Navigator.pushNamed(context, '/bongkarkd')
              : null,
          disabled: !_can('bongkar_kd:read'),
        ),
      ],
    );
  }

  // =================== TAB: AKUN ===================
  Widget _buildAkunTab(BuildContext context) {
    return _tabScaffold(
      title: 'Akun',
      description: 'Kelola profil & keamanan.',
      primary: _primaryAction(
        context,
        label: 'Ganti Password',
        icon: Icons.lock_reset,
        onTap: () => _showChangePasswordDialog(context),
      ),
      extras: [
        _quickCard(
          context,
          title: 'Keluar',
          subtitle: 'Logout dari aplikasi',
          icon: Icons.logout,
          color: Colors.red,
          onTap: () => _logout(context),
        ),
      ],
    );
  }

  // =====================================================
  // Reusable pieces
  // =====================================================

  // Panel identitas + metrik operasional utama (SPK berjalan).
  Widget _buildHeroPanel(BuildContext context, DashboardSummaryViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBrand,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kBrand.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _todayLabel(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (_can('spk:read')) ...[
            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withOpacity(0.16)),
            const SizedBox(height: 16),
            _buildHeroMetric(context, vm),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroMetric(BuildContext context, DashboardSummaryViewModel vm) {
    final loading = vm.isLoading && vm.activeSpkCount == null;
    final errored = vm.qcError.isNotEmpty && vm.activeSpkCount == null;
    final helper = errored
        ? 'Gagal memuat — ketuk untuk coba lagi'
        : 'Ketuk untuk mulai QC';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (errored) {
          vm.refresh(mapping: false, qc: true);
        } else {
          Navigator.pushNamed(context, '/qc-spk-bj');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        vm.activeSpkCount?.toString() ?? '—',
                        style: const TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SPK sedang berjalan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    helper,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.66),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              errored ? Icons.refresh : Icons.arrow_forward,
              size: 18,
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
      ),
    );
  }

  // Label seksi ala tipografi (kecil, uppercase, tracking).
  Widget _sectionLabel(String text, {Widget? trailing}) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.grey.shade500,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _inlineLink(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kBrand,
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: kBrand),
          ],
        ),
      ),
    );
  }

  // =================== SECTION: RINGKASAN MAPPING ===================
  Widget _buildMappingRingkasan(
      BuildContext context, DashboardSummaryViewModel vm) {
    final loading = vm.isLoading &&
        vm.totalLokasi == 0 &&
        vm.mappingError.isEmpty;
    final errored = vm.mappingError.isNotEmpty && vm.totalLokasi == 0;

    Widget body;
    if (loading) {
      body = Row(
        children: const [
          Expanded(child: DashboardStatShimmer()),
          SizedBox(width: 10),
          Expanded(child: DashboardStatShimmer()),
          SizedBox(width: 10),
          Expanded(child: DashboardStatShimmer()),
        ],
      );
    } else if (errored) {
      body = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kHairline),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 18, color: Colors.redAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                vm.mappingError,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
            TextButton(
              onPressed: () => vm.refresh(mapping: true, qc: false),
              style: TextButton.styleFrom(
                foregroundColor: kBrand,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    } else {
      body = Row(
        children: [
          Expanded(
            child: DashboardStatTile(
              value: '${vm.lokasiTerisi}/${vm.totalLokasi}',
              label: 'Lokasi terisi',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DashboardStatTile(
              value: '${vm.totalLabel}',
              label: 'Label termapping',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DashboardStatTile(
              value: '${vm.lokasiKosong}',
              label: 'Lokasi kosong',
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(
          'Ringkasan Mapping',
          trailing: _inlineLink(
              'Buka', () => Navigator.pushNamed(context, '/mapping')),
        ),
        const SizedBox(height: 12),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushNamed(context, '/mapping'),
          child: body,
        ),
      ],
    );
  }

  // =================== SECTION: MENU (GRID) ===================
  Widget _buildModuleGrid(BuildContext context) {
    final items = <_ModuleSpec>[
      _ModuleSpec('stock_opname:read', 'Stock Opname', 'Kelola stok kayu',
          Icons.checklist_rtl_outlined, '/stockopname'),
      _ModuleSpec('mapping:read', 'Mapping', 'Posisi & lokasi kayu',
          Icons.location_on_outlined, '/mapping'),
      _ModuleSpec('bongkar_kd:read', 'Bongkar KD', 'Posisi setelah proses KD',
          Icons.warehouse_outlined, '/bongkarkd'),
      _ModuleSpec('nyangkut:read', 'Nyangkut', 'Cek label tersangkut',
          Icons.pending_actions_outlined, '/nyangkut'),
      _ModuleSpec('kayu_bulat:read', 'Kayu Bulat', 'Data kayu bulat',
          Icons.forest_outlined, '/kayu-bulat'),
      _ModuleSpec('qc_sawmill:read', 'QC Sawmill', 'Quality control sawmill',
          Icons.rule_folder_outlined, '/qc-sawmill'),
      _ModuleSpec('spk:read', 'QC Barang Jadi', 'QC per bundle sesuai SPK',
          Icons.fact_check_outlined, '/qc-spk-bj'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: [
        for (final m in items)
          DashboardModuleTile(
            icon: m.icon,
            title: m.title,
            subtitle: m.subtitle,
            allowed: _can(m.perm),
            onTap: () => Navigator.pushNamed(context, m.route),
          ),
      ],
    );
  }

  // ===== Layout helper utk tab selain Beranda =====

  Widget _tabScaffold({
    required String title,
    required String description,
    required Widget primary,
    List<Widget> extras = const [],
  }) {
    return Container(
      color: kCanvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          _miniHeader(title: title, subtitle: description),
          const SizedBox(height: 16),
          primary,
          ...extras.map((w) =>
              Padding(padding: const EdgeInsets.only(top: 12), child: w)),
        ],
      ),
    );
  }

  Widget _miniHeader({required String title, required String subtitle}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBrand,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kBrand.withOpacity(0.20),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  color: Colors.white.withOpacity(.75), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _primaryAction(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    String? disabledTooltip,
  }) {
    final color = const Color(0xFF755330);
    final btn = ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );

    if (onTap != null) return btn;
    return Tooltip(message: disabledTooltip ?? _deniedMsg, child: btn);
  }

  Widget _quickCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool disabled = false,
  }) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kHairline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: disabled ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.10),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: disabled ? Colors.grey.shade400 : color),
              ],
            ),
          ),
        ),
      ),
    );

    if (!disabled) return card;
    return Tooltip(
      message: _deniedMsg,
      child: Opacity(opacity: .5, child: card),
    );
  }

  // === Exit dialog ===
  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Konfirmasi'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Tidak')),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF755330),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Ya', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

/// Definisi satu modul di grid menu.
class _ModuleSpec {
  final String perm;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  const _ModuleSpec(
      this.perm, this.title, this.subtitle, this.icon, this.route);
}
