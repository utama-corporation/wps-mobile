import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_model/mapping_lokasi_view_model.dart';
import '../model/mapping_lokasi_model.dart';
import '../../../core/widgets/loading_skeleton.dart';
import 'barcode_qr_scan_mapping_screen.dart';

/// Layar kedua flow Mapping Lokasi.
///
/// Menampilkan daftar label yang berada pada satu [idLokasi]
/// (GET /api/mapping/lokasi-labels) lengkap dengan jenis kayu dan detail
/// ukuran. FAB "Scan QR" membuka kamera untuk memindai label dan memindahkan
/// label tersebut ke [idLokasi] ini.
class MappingLokasiLabelScreen extends StatefulWidget {
  final String idLokasi;
  final String blok;

  const MappingLokasiLabelScreen({
    super.key,
    required this.idLokasi,
    required this.blok,
  });

  @override
  State<MappingLokasiLabelScreen> createState() =>
      _MappingLokasiLabelScreenState();
}

class _MappingLokasiLabelScreenState extends State<MappingLokasiLabelScreen> {
  static const _brown = Color(0xFF755330);
  static const _brownDark = Color(0xFF5A3F24);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MappingLokasiViewModel>().fetchLokasiLabels(widget.idLokasi);
    });
  }

  Future<void> _refresh() =>
      context.read<MappingLokasiViewModel>().fetchLokasiLabels(widget.idLokasi);

  Future<void> _openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeQrScanMappingScreen(
          selectedFilter: 'all',
          idLokasi: widget.idLokasi,
        ),
      ),
    );
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _brown,
        foregroundColor: Colors.white,
        title: Text(widget.idLokasi,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Consumer<MappingLokasiViewModel>(
        builder: (context, vm, child) {
          return Column(
            children: [
              _Header(
                brown: _brown,
                brownDark: _brownDark,
                totalLabel: vm.totalLabelData,
                totalPcs: vm.totalJumlah,
                totalM3: vm.totalM3,
                totalTon: vm.totalTon,
                loading: vm.isLabelLoading && vm.labelList.isEmpty,
              ),
              Expanded(child: _buildBody(vm)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _brown,
        foregroundColor: Colors.white,
        onPressed: _openScanner,
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan QR'),
      ),
    );
  }

  Widget _buildBody(MappingLokasiViewModel vm) {
    if (vm.isLabelLoading && vm.labelList.isEmpty) {
      return const LoadingSkeleton();
    }
    if (vm.labelError.isNotEmpty) {
      return _StatePlaceholder(
        onRefresh: _refresh,
        icon: Icons.cloud_off_rounded,
        iconColor: Colors.redAccent,
        title: 'Gagal memuat label',
        subtitle: vm.labelError,
      );
    }
    if (vm.labelList.isEmpty) {
      return _StatePlaceholder(
        onRefresh: _refresh,
        icon: Icons.inbox_rounded,
        iconColor: Colors.grey,
        title: 'Belum ada label di lokasi ini',
        subtitle: 'Gunakan tombol Scan QR untuk memindahkan label ke sini',
      );
    }

    return RefreshIndicator(
      color: _brown,
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: vm.labelList.length,
        itemBuilder: (context, index) => _LabelCard(label: vm.labelList[index]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header brand + statistik
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final Color brown;
  final Color brownDark;
  final int totalLabel;
  final int totalPcs;
  final String totalM3;
  final String totalTon;
  final bool loading;

  const _Header({
    required this.brown,
    required this.brownDark,
    required this.totalLabel,
    required this.totalPcs,
    required this.totalM3,
    required this.totalTon,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.label_rounded,
                  value: loading ? '–' : '$totalLabel',
                  label: 'Total Label',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  icon: Icons.forest_rounded,
                  value: loading ? '–' : '$totalPcs',
                  label: 'Total Batang',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.view_in_ar_rounded,
                  value: loading ? '–' : totalM3,
                  label: 'Total M³',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatChip(
                  icon: Icons.scale_rounded,
                  value: loading ? '–' : totalTon,
                  label: 'Total Ton (ST)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Kartu label -> membuka modal bottom sheet detail saat di-tap
// ---------------------------------------------------------------------------
class _LabelCard extends StatelessWidget {
  final LokasiLabelModel label;

  const _LabelCard({required this.label});

  void _openDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LabelDetailSheet(label: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1.5,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetail(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        label.labelNo,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label.dateCreate ?? '-',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.forest_rounded,
                        size: 14, color: Colors.brown.shade400),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        (label.jenis ?? '').isNotEmpty
                            ? (label.jenis! +
                                ((label.singkatan ?? '').isNotEmpty
                                    ? ' (${label.singkatan})'
                                    : ''))
                            : (label.singkatan ?? '-'),
                        style: TextStyle(
                            fontSize: 12.5, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
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
// Modal bottom sheet: detail label
// ---------------------------------------------------------------------------
class _LabelDetailSheet extends StatelessWidget {
  final LokasiLabelModel label;

  const _LabelDetailSheet({required this.label});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label.labelNo,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F4EF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow(Icons.category_rounded, 'Tipe label',
                              label.labelType),
                          _detailRow(
                              Icons.forest_rounded,
                              'Jenis kayu',
                              (label.jenis ?? '-') +
                                  ((label.singkatan ?? '').isNotEmpty
                                      ? ' (${label.singkatan})'
                                      : '')),
                          _detailRow(Icons.event_rounded, 'Tanggal',
                              label.dateCreate ?? '-'),
                          _detailRow(Icons.tag_rounded, 'Total batang',
                              '${label.jumlah}'),
                          _detailRow(
                              label.isTon
                                  ? Icons.scale_rounded
                                  : Icons.view_in_ar_rounded,
                              label.isTon ? 'Total Ton' : 'Total M³',
                              label.volume),
                          _detailRow(Icons.list_alt_rounded, 'Jumlah detail',
                              '${label.totalDetails}',
                              last: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Detail Ukuran',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    if (label.hasDetails)
                      _DetailTable(details: label.details)
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Tidak ada detail ukuran',
                          style: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                              fontSize: 12.5),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.brown.shade300),
          const SizedBox(width: 10),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTable extends StatelessWidget {
  final List<LokasiLabelDetailModel> details;

  const _DetailTable({required this.details});

  String _fmt(double? value) {
    if (value == null) return '-';
    if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF0EBE3)),
          headingRowHeight: 38,
          dataRowMinHeight: 34,
          dataRowMaxHeight: 40,
          headingTextStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A3F24),
              fontSize: 11.5),
          dataTextStyle: const TextStyle(fontSize: 11.5, color: Colors.black87),
          columnSpacing: 28,
          horizontalMargin: 16,
          columns: const [
            DataColumn(label: Text('No'), numeric: true),
            DataColumn(label: Text('Tebal'), numeric: true),
            DataColumn(label: Text('Lebar'), numeric: true),
            DataColumn(label: Text('Panjang'), numeric: true),
            DataColumn(label: Text('Pcs'), numeric: true),
          ],
          rows: details.map<DataRow>((d) {
            return DataRow(cells: [
              DataCell(Text(d.noUrut?.toString() ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(_fmt(d.tebal))),
              DataCell(Text(_fmt(d.lebar))),
              DataCell(Text(_fmt(d.panjang))),
              DataCell(Text(d.jmlhBatang?.toString() ?? '0',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green))),
            ]);
          }).toList(),
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
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
