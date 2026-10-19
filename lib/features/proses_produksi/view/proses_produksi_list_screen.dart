// lib/features/proses_produksi/view/proses_produksi_list_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_info_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../model/proses_produksi_data.dart';
import '../model/proses_produksi_process.dart';
import '../view_model/proses_produksi_list_view_model.dart';
import '../widgets/proses_produksi_report_pdf.dart';

/// Daftar riwayat produksi untuk satu proses (S4S, Moulding, dst).
///
/// Kolom & urutan data mengikuti WPS Tablet: NoProduksi, Tanggal, Shift,
/// Mesin, Operator. Filter search dijalankan di sisi client.
class ProsesProduksiListScreen extends StatefulWidget {
  final ProsesProduksiProcess process;

  const ProsesProduksiListScreen({
    super.key,
    required this.process,
  });

  @override
  State<ProsesProduksiListScreen> createState() =>
      _ProsesProduksiListScreenState();
}

class _ProsesProduksiListScreenState extends State<ProsesProduksiListScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    // Load awal dijalankan di dalam `create:` ChangeNotifierProvider (lihat
    // build()) karena hanya di subtree itu view model-nya bisa di-resolve.
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(ProsesProduksiListViewModel vm, String text) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      vm.setQuery(text);
    });
  }

  void _clearSearch(ProsesProduksiListViewModel vm) {
    _searchDebounce?.cancel();
    _searchCtrl.clear();
    vm.clearQuery();
    setState(() {});
  }

  Future<void> _showDetail(ProsesProduksiData row) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.noProduksi,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: kProsesProduksiBrand,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.process.title,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                _SheetRow(
                    icon: Icons.calendar_today,
                    label: 'Tanggal',
                    value:
                        DateFormatter.fullFromYmd(sheetContext, row.tanggal)),
                _SheetRow(
                    icon: Icons.schedule, label: 'Shift', value: row.shift),
                _SheetRow(
                    icon: Icons.precision_manufacturing_outlined,
                    label: 'Mesin',
                    value: row.namaMesin),
                _SheetRow(
                    icon: Icons.person_outline,
                    label: 'Operator',
                    value: row.operatorName),
                _SheetRow(
                    icon: Icons.timelapse,
                    label: 'Jam Kerja',
                    value: row.jamKerja),
                _SheetRow(
                    icon: Icons.groups_outlined,
                    label: 'Jmlh Anggota',
                    value: row.jmlhAnggota),
                _SheetRow(
                    icon: Icons.forest_outlined,
                    label: 'Jenis Output',
                    value: row.jenisOutput),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      openProsesProduksiReportPdf(
                          context, widget.process, row.noProduksi);
                    },
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Buka Laporan PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kProsesProduksiBrand,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ProsesProduksiListViewModel(widget.process)..refresh(),
      child: Consumer<ProsesProduksiListViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              backgroundColor: kProsesProduksiBrand,
              elevation: 0,
              toolbarHeight: 64,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.process.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Proses Produksi • ${vm.totalFiltered} data',
                    style: TextStyle(
                        color: Colors.white.withOpacity(.75), fontSize: 12),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText:
                            'Cari No Produksi, Shift, Tanggal, Mesin, Operator...',
                        hintStyle:
                            TextStyle(color: Colors.grey[500], fontSize: 13.5),
                        border: InputBorder.none,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => _clearSearch(vm),
                              )
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: (text) => _onSearchChanged(vm, text),
                    ),
                  ),
                ),
              ),
            ),
            body: RefreshIndicator(
              color: kProsesProduksiBrand,
              onRefresh: () => vm.refresh(),
              child: _buildBody(vm),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ProsesProduksiListViewModel vm) {
    if (vm.isLoading && vm.items.isEmpty) {
      return const LoadingSkeleton();
    }

    if (vm.error.isNotEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 48, bottom: 24),
        children: [
          ErrorState(
            message: vm.error,
            primaryAction: FilledButton.tonal(
              onPressed: vm.isLoading ? null : vm.refresh,
              child: const Text('Coba lagi'),
            ),
          ),
        ],
      );
    }

    if (vm.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          EmptyState(
            title: vm.query.isEmpty ? 'Belum ada data' : 'Tidak ditemukan',
            subtitle: vm.query.isEmpty
                ? 'Belum ada riwayat produksi ${widget.process.title}.'
                : 'Coba kata kunci lain atau periksa ejaan',
            icon: vm.query.isEmpty ? Icons.inbox_outlined : Icons.search_off,
          ),
          const SizedBox(height: 24),
        ],
      );
    }

    final total = vm.totalFiltered;
    final shown = vm.items.length;

    final list = NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter <= 200) vm.loadMore();
        return false;
      },
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: vm.items.length + (vm.canLoadMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i >= vm.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  color: kProsesProduksiBrand,
                ),
              ),
            );
          }

          final row = vm.items[i];

          return AppInfoCard(
            title: row.noProduksi,
            subtitle: DateFormatter.fullFromYmd(ctx, row.tanggal),
            leadingIcon: widget.process.icon,
            brandColor: kProsesProduksiBrand,
            rows: [
              InfoRowData(
                icon: Icons.schedule,
                label: 'Shift',
                value: row.shift,
                color: Colors.blue.shade700,
              ),
              InfoRowData(
                icon: Icons.precision_manufacturing_outlined,
                label: 'Mesin',
                value: row.namaMesin,
                color: Colors.teal.shade700,
              ),
              InfoRowData(
                icon: Icons.person_outline,
                label: 'Operator',
                value: row.operatorName,
                color: Colors.green.shade700,
              ),
              if (row.jenisOutput.isNotEmpty)
                InfoRowData(
                  icon: Icons.forest_outlined,
                  label: 'Jenis Output',
                  value: row.jenisOutput,
                  color: const Color(0xFF334B44),
                ),
            ],
            onTap: () => _showDetail(row),
          );
        },
      ),
    );

    if (shown >= total) return list;

    return Column(
      children: [
        Expanded(child: list),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text(
            'Menampilkan $shown dari $total data',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
      ],
    );
  }
}

/// Baris info label/value di dalam bottom sheet detail.
class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SheetRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
