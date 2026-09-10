// lib/features/qc_spk_bj/view/qc_spk_line_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_info_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../model/qc_spk_line.dart';
import '../view_model/qc_spk_line_view_model.dart';
import 'qc_spk_bundle_screen.dart';

const _brand = Color(0xFF755330);

class QcSpkLineScreen extends StatelessWidget {
  final String noSPK;
  const QcSpkLineScreen({super.key, required this.noSPK});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QcSpkLineViewModel()..load(noSPK),
      child: Consumer<QcSpkLineViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              backgroundColor: _brand,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pilih Produk SPK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    noSPK,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            body: RefreshIndicator(
              color: _brand,
              onRefresh: vm.refresh,
              child: Builder(
                builder: (_) {
                  if (vm.isLoading && vm.items.isEmpty) {
                    return const _LoadingList();
                  }
                  if (vm.error.isNotEmpty && vm.items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 48, bottom: 24),
                      children: [
                        ErrorState(
                          message: vm.error,
                          primaryAction: TextButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Muat ulang'),
                            onPressed: vm.refresh,
                          ),
                        ),
                      ],
                    );
                  }
                  if (!vm.isLoading && vm.items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 48),
                        EmptyState(
                          title: 'Tidak ada baris',
                          subtitle: 'SPK ini belum punya rincian barang jadi',
                          icon: Icons.inbox_outlined,
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: vm.items.length,
                    itemBuilder: (ctx, i) {
                      final line = vm.items[i];
                      return _LineCard(
                        noSPK: noSPK,
                        line: line,
                        onReturn: vm.refresh,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  final String noSPK;
  final QcSpkLine line;
  final Future<void> Function() onReturn;

  const _LineCard({
    required this.noSPK,
    required this.line,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final done = line.isComplete;
    final accent = done ? Colors.green.shade700 : _brand;
    final progressColor = done ? Colors.green.shade700 : Colors.orange.shade800;

    return AppInfoCard(
      title: line.namaBarangJadi ?? 'Barang Jadi #${line.idBarangJadi}',
      subtitle: line.namaJenisKayu ?? '-',
      subtitleIcon: Icons.category_outlined,
      brandColor: accent,
      backgroundColor: done ? Colors.green.shade50 : null,
      leadingIcon: done ? Icons.check_circle : Icons.inventory_2_outlined,
      rows: [
        InfoRowData(
          icon: Icons.straighten_outlined,
          label: 'Dimensi (T x L x P)',
          value: line.dimensiLabel,
          color: Colors.teal.shade700,
        ),
        InfoRowData(
          icon: Icons.inventory_outlined,
          label: 'Bundle / Pcs per Bundle',
          value: '${line.bundle} / ${line.pcsPerBundle}',
          color: Colors.deepPurple.shade400,
        ),
        InfoRowData(
          icon: line.isComplete
              ? Icons.check_circle_outline
              : Icons.hourglass_bottom_outlined,
          label: 'Progress QC',
          value: line.progressLabel,
          color: progressColor,
        ),
      ],
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QcSpkBundleScreen(noSPK: noSPK, line: line),
          ),
        );
        await onReturn();
      },
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 200),
        Center(child: CircularProgressIndicator(color: _brand)),
        SizedBox(height: 200),
      ],
    );
  }
}
