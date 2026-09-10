import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/permission_storage.dart';
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
  }

  bool _can(String code) => _permissions?.contains(code) ?? false;

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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF755330).withOpacity(0.05), Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildMenuSection(context),
          ],
        ),
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

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF755330), Colors.brown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF755330).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Datang',
                    style: TextStyle(
                        fontSize: 16, color: Colors.white.withOpacity(0.9))),
                const SizedBox(height: 4),
                const Text('WPS Mobile',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                Text('Wood Processing System',
                    style: TextStyle(
                        fontSize: 14, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.dashboard, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Menu Utama',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 16),

        _menuCardGuarded(
          context,
          allowed: _can('stock_opname:read'),
          title: 'Stock Opname',
          subtitle: 'Kelola stok kayu',
          icon: Icons.checklist_rtl_rounded,
          color: const Color(0xFF755330),
          onTap: () => Navigator.pushNamed(context, '/stockopname'),
        ),
        const SizedBox(height: 12),

        _menuCardGuarded(
          context,
          allowed: _can('mapping:read'),
          title: 'Mapping',
          subtitle: 'Kelola posisi kayu',
          icon: Icons.location_on,
          color: const Color(0xFF755330),
          onTap: () => Navigator.pushNamed(context, '/mapping'),
        ),
        const SizedBox(height: 12),

        _menuCardGuarded(
          context,
          allowed: _can('bongkar_kd:read'),
          title: 'Bongkar KD',
          subtitle: 'Kelola posisi setelah proses KD',
          icon: Icons.warehouse,
          color: const Color(0xFF755330),
          onTap: () => Navigator.pushNamed(context, '/bongkarkd'),
        ),
        const SizedBox(height: 12),

        _menuCardGuarded(
          context,
          allowed: _can('nyangkut:read'),
          title: 'Nyangkut',
          subtitle: 'Cek label yang tersangkut',
          icon: Icons.pending_actions,
          color: const Color(0xFF755330),
          onTap: () => Navigator.pushNamed(context, '/nyangkut'),
        ),
        const SizedBox(height: 12),

        _menuCardGuarded(
          context,
          allowed: _can('kayu_bulat:read'),
          title: 'Kayu Bulat',
          subtitle: 'Kelola data kayu bulat',
          icon: Icons.inventory_2_sharp,
          color: const Color(0xFF755330),
          onTap: () => Navigator.pushNamed(context, '/kayu-bulat'),
        ),
        const SizedBox(height: 12),

        _menuCardGuarded(
          context,
          allowed: _can('qc_sawmill:read'),
          title: 'QC Sawmill',
          subtitle: 'Kelola data QC Sawmill',
          icon: Icons.library_add_check_outlined,
          color: const Color(0xFF755330),
          onTap: () => Navigator.pushNamed(context, '/qc-sawmill'),
        ),
        const SizedBox(height: 12),

        _menuCardGuarded(
          context,
          allowed: _can('spk:read'),
          title: 'QC Barang Jadi',
          subtitle: 'QC per bundle sesuai SPK barang jadi',
          icon: Icons.fact_check_outlined,
          color: const Color(0xFF755330),
          onTap: () => Navigator.pushNamed(context, '/qc-spk-bj'),
        ),
        // const SizedBox(height: 12),
        //
        // _buildMenuCard(
        //   context,
        //   title: 'Akun',
        //   subtitle: 'Kelola password akun',
        //   icon: Icons.person,
        //   color: const Color(0xFF755330),
        //   onTap: () => _showChangePasswordDialog(context),
        // ),
      ],
    );
  }

  // ===== Reusable cards & guards =====

  Widget _menuCardGuarded(
    BuildContext context, {
    required bool allowed,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final card = _buildMenuCard(
      context,
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      onTap: allowed ? onTap : () {},
    );

    if (allowed) return card;

    return Tooltip(
      message: _deniedMsg,
      triggerMode: TooltipTriggerMode.longPress,
      child: Opacity(
          opacity: 0.5, child: IgnorePointer(ignoring: true, child: card)),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.all(20),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.arrow_forward_ios, color: color, size: 16),
        ),
      ),
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF755330).withOpacity(0.05), Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _miniHeader(title: title, subtitle: description),
          const SizedBox(height: 12),
          primary,
          ...extras.map((w) =>
              Padding(padding: const EdgeInsets.only(top: 12), child: w)),
        ],
      ),
    );
  }

  Widget _miniHeader({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF755330),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF755330).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.dashboard_customize, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(.9))),
              ],
            ),
          ),
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
    final card = Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: onTap,
        enabled: !disabled,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing:
            Icon(Icons.chevron_right, color: disabled ? Colors.grey : color),
      ),
    );

    if (!disabled) return card;
    return Tooltip(
        message: _deniedMsg,
        child: Opacity(opacity: .5, child: IgnorePointer(child: card)));
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
