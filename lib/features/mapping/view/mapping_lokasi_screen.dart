import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/mapping_lokasi_view_model.dart';
import '../model/mapping_lokasi_model.dart';
import '../../../core/widgets/loading_skeleton.dart';
import 'mapping_lokasi_label_screen.dart';

/// Layar pertama flow Mapping Lokasi.
///
/// Menampilkan ringkasan setiap lokasi beserta jumlah label yang masih berada
/// di lokasi tersebut (GET /api/mapping/lokasi-summary). Ketika salah satu
/// lokasi dipilih, user diarahkan ke [MappingLokasiLabelScreen] untuk melihat
/// detail label pada lokasi itu dan melakukan scan update lokasi.
class MappingLokasiScreen extends StatefulWidget {
  const MappingLokasiScreen({super.key});

  @override
  State<MappingLokasiScreen> createState() => _MappingLokasiScreenState();
}

class _MappingLokasiScreenState extends State<MappingLokasiScreen> {
  static const _brown = Color(0xFF755330);
  static const _brownDark = Color(0xFF5A3F24);

  final TextEditingController _searchController = TextEditingController();
  String _keyword = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MappingLokasiViewModel>().fetchLokasiSummary();
    });
    _searchController.addListener(() {
      setState(() => _keyword = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LokasiSummaryModel> _applyFilter(List<LokasiSummaryModel> source) {
    if (_keyword.isEmpty) return source;
    return source.where((l) {
      return l.idLokasi.toLowerCase().contains(_keyword) ||
          (l.description ?? '').toLowerCase().contains(_keyword);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: _brown,
        foregroundColor: Colors.white,
        title: const Text(
          'Mapping Lokasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Consumer<MappingLokasiViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              _Header(
                brown: _brown,
                brownDark: _brownDark,
                controller: _searchController,
                totalLokasi: vm.lokasiSummaryList.length,
                lokasiTerisi:
                    vm.lokasiSummaryList.where((l) => l.jumlahLabel > 0).length,
                totalLabel: vm.lokasiSummaryList
                    .fold<int>(0, (s, l) => s + l.jumlahLabel),
                loading: vm.isSummaryLoading && vm.lokasiSummaryList.isEmpty,
              ),
              Expanded(child: _buildBody(vm)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(MappingLokasiViewModel vm) {
    if (vm.isSummaryLoading && vm.lokasiSummaryList.isEmpty) {
      return const LoadingSkeleton();
    }
    if (vm.summaryError.isNotEmpty) {
      return _StatePlaceholder(
        onRefresh: vm.fetchLokasiSummary,
        icon: Icons.cloud_off_rounded,
        iconColor: Colors.redAccent,
        title: 'Gagal memuat lokasi',
        subtitle: vm.summaryError,
      );
    }

    final data = _applyFilter(vm.lokasiSummaryList);
    if (data.isEmpty) {
      return _StatePlaceholder(
        onRefresh: vm.fetchLokasiSummary,
        icon: _keyword.isEmpty ? Icons.inbox_rounded : Icons.search_off_rounded,
        iconColor: Colors.grey,
        title: _keyword.isEmpty
            ? 'Belum ada lokasi'
            : 'Lokasi tidak ditemukan',
        subtitle: _keyword.isEmpty
            ? 'Tarik ke bawah untuk memuat ulang'
            : 'Coba kata kunci lain',
      );
    }

    return RefreshIndicator(
      color: _brown,
      onRefresh: vm.fetchLokasiSummary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 28),
        itemCount: data.length,
        itemBuilder: (context, index) => _LokasiCard(
          brown: _brown,
          lokasi: data[index],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MappingLokasiLabelScreen(
                idLokasi: data[index].idLokasi,
                blok: data[index].blok,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header: gradient brand + statistik + search
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final Color brown;
  final Color brownDark;
  final TextEditingController controller;
  final int totalLokasi;
  final int lokasiTerisi;
  final int totalLabel;
  final bool loading;

  const _Header({
    required this.brown,
    required this.brownDark,
    required this.controller,
    required this.totalLokasi,
    required this.lokasiTerisi,
    required this.totalLabel,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [brown, brownDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: loading ? '–' : '$totalLokasi',
                  label: 'Total Lokasi',
                  icon: Icons.warehouse_rounded,
                ),
              ),
              _divider(),
              Expanded(
                child: _StatTile(
                  value: loading ? '–' : '$lokasiTerisi',
                  label: 'Terisi',
                  icon: Icons.inventory_2_rounded,
                ),
              ),
              _divider(),
              Expanded(
                child: _StatTile(
                  value: loading ? '–' : _compact(totalLabel),
                  label: 'Total Label',
                  icon: Icons.label_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(14),
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari kode lokasi / keterangan',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: controller.clear,
                      ),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 34,
        color: Colors.white.withOpacity(0.22),
      );

  static String _compact(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return '$v';
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.85), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu lokasi
// ---------------------------------------------------------------------------
class _LokasiCard extends StatelessWidget {
  final Color brown;
  final LokasiSummaryModel lokasi;
  final VoidCallback onTap;

  const _LokasiCard({
    required this.brown,
    required this.lokasi,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool terisi = lokasi.jumlahLabel > 0;
    final Color accent = terisi ? brown : Colors.grey.shade400;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1.5,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Aksen warna kiri
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.warehouse_rounded, color: accent),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        lokasi.idLokasi,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (lokasi.description ?? '').isNotEmpty
                            ? lokasi.description!
                            : 'Tanpa keterangan',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: terisi
                              ? brown.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.label_rounded,
                                size: 13,
                                color: terisi ? brown : Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${lokasi.jumlahLabel}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: terisi ? brown : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'label',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.chevron_right_rounded,
                      color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Placeholder state (error / kosong) yang tetap bisa di-pull-to-refresh
// ---------------------------------------------------------------------------
class _StatePlaceholder extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _StatePlaceholder({
    required this.onRefresh,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 56, color: iconColor),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
