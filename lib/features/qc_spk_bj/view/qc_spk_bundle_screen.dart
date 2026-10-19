// lib/features/qc_spk_bj/view/qc_spk_bundle_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_toast.dart';
import '../model/qc_spk_bundle.dart';
import '../model/qc_spk_line.dart';
import '../view_model/qc_spk_bundle_view_model.dart';
import 'qc_spk_bundle_input_screen.dart';

const _brand = Color(0xFF2E6F5D);

class QcSpkBundleScreen extends StatefulWidget {
  final String noSPK;
  final QcSpkLine line;

  const QcSpkBundleScreen({
    super.key,
    required this.noSPK,
    required this.line,
  });

  @override
  State<QcSpkBundleScreen> createState() => _QcSpkBundleScreenState();
}

class _QcSpkBundleScreenState extends State<QcSpkBundleScreen> {
  /// Hanya berisi bundle yang SUDAH tersimpan di server (urut noBundle).
  final List<QcSpkBundle> _working = [];
  bool _seeded = false;

  int get _maxBundle => widget.line.bundle;

  void _seed(List<QcSpkBundle> serverItems) {
    _working
      ..clear()
      ..addAll(serverItems);
    _working.sort((a, b) => (a.noBundle ?? 0).compareTo(b.noBundle ?? 0));
    _seeded = true;
  }

  /// Nomor bundle berikutnya (terkecil yang belum dipakai).
  int get _nextBundleNo {
    final used = {
      for (final b in _working)
        if (b.noBundle != null) b.noBundle!,
    };
    var n = 1;
    while (used.contains(n)) {
      n++;
    }
    return n;
  }

  bool get _canAdd => _maxBundle > 0 && _working.length < _maxBundle;

  Future<void> _openInput(
    QcSpkBundleViewModel vm, {
    required int noBundle,
    QcSpkBundle? initial,
  }) async {
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => QcSpkBundleInputScreen(
          vm: vm,
          spec: widget.line,
          noBundle: noBundle,
          initial: initial,
        ),
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        _seeded = false;
        _seed(vm.items);
      });
    }
  }

  void _onAddPressed(QcSpkBundleViewModel vm) {
    if (!_canAdd) {
      AppToast.warning(
        context,
        'Sudah mencapai maksimal $_maxBundle bundle sesuai SPK',
      );
      return;
    }
    _openInput(vm, noBundle: _nextBundleNo);
  }

  Future<void> _confirmDelete(QcSpkBundleViewModel vm, QcSpkBundle bundle) async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Bundle'),
        content: Text(
          'Yakin ingin menghapus bundle #${bundle.noBundle ?? "-"} '
          'beserta fotonya?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Hapus',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final deleted = await vm.deleteOne(bundle.noBundle ?? 0);
    if (!mounted) return;
    if (deleted) {
      AppToast.success(context, 'Bundle #${bundle.noBundle} dihapus.');
      setState(() {
        _seeded = false;
        _seed(vm.items);
      });
    } else {
      AppToast.error(context, vm.error.isEmpty ? 'Gagal menghapus bundle' : vm.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.line;

    return ChangeNotifierProvider(
      create: (_) => QcSpkBundleViewModel()..load(widget.noSPK, line.lineNo),
      child: Consumer<QcSpkBundleViewModel>(
        builder: (context, vm, _) {
          if (!_seeded && !vm.isLoading) {
            _seed(vm.items);
          }

          final showEmpty = _seeded && _working.isEmpty;

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              backgroundColor: _brand,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QC ${line.namaBarangJadi ?? "Barang Jadi"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${line.namaJenisKayu ?? "Jenis Kayu"}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              backgroundColor: _canAdd ? _brand : Colors.grey.shade400,
              onPressed: () => _onAddPressed(vm),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                _canAdd
                    ? 'Tambah Bundle (${_working.length}/$_maxBundle)'
                    : 'Maks $_maxBundle bundle',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            body: vm.isLoading && !_seeded
                ? const Center(child: CircularProgressIndicator(color: _brand))
                : Column(
                    children: [
                      _SpecHeader(
                        line: line,
                        current: _working.length,
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          color: _brand,
                          onRefresh: () async {
                            await vm.refresh();
                            if (mounted) {
                              setState(() {
                                _seeded = false;
                                _seed(vm.items);
                              });
                            }
                          },
                          child: showEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 80),
                                    Icon(Icons.inbox_outlined,
                                        size: 56, color: Colors.grey.shade400),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: Text(
                                        'Belum ada bundle QC',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Center(
                                      child: Text(
                                        'Tap tombol + untuk menambah bundle '
                                        '(maksimal $_maxBundle)',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.grey.shade600),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 12, 12, 96),
                                  itemCount: _working.length,
                                  itemBuilder: (ctx, i) {
                                    final b = _working[i];
                                    return _BundleCard(
                                      bundle: b,
                                      onTap: () => _openInput(
                                        vm,
                                        noBundle: b.noBundle ?? (i + 1),
                                        initial: b,
                                      ),
                                      onDelete: () => _confirmDelete(vm, b),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

class _SpecHeader extends StatelessWidget {
  final QcSpkLine line;
  final int current;

  const _SpecHeader({required this.line, required this.current});

  @override
  Widget build(BuildContext context) {
    final complete = line.bundle > 0 && current >= line.bundle;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spec: ${line.dimensiLabel}  ·  ${line.namaJenisKayu ?? "-"}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                complete ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color:
                    complete ? Colors.green.shade700 : Colors.orange.shade800,
              ),
              const SizedBox(width: 6),
              Text(
                'Bundle QC: $current / ${line.bundle}   (Pcs/bundle: ${line.pcsPerBundle})',
                style: TextStyle(
                  fontSize: 13,
                  color:
                      complete ? Colors.green.shade800 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BundleCard extends StatelessWidget {
  final QcSpkBundle bundle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BundleCard({
    required this.bundle,
    required this.onTap,
    required this.onDelete,
  });

  String _f(double? n) {
    if (n == null) return '-';
    return n % 1 == 0 ? n.toStringAsFixed(0) : n.toString();
  }

  int _photoCount(QcSpkBundle b) => b.photoCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ListTile(
        //onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 12, 6),
        leading: CircleAvatar(
          backgroundColor: Colors.green.withOpacity(0.12),
          child: Text(
            '${bundle.noBundle ?? "-"}',
            style: TextStyle(
              color: Colors.green.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${_f(bundle.tebal)} x ${_f(bundle.lebar)} x ${_f(bundle.panjang)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text('Jumlah pcs: ${bundle.jumlahPcs ?? "-"}'),
            if (bundle.hasAnyPhoto) ...[
              const SizedBox(width: 8),
              Icon(Icons.photo_camera_outlined,
                  size: 14, color: Colors.green.shade700),
              Text(
                ' ${_photoCount(bundle)}',
                style: TextStyle(fontSize: 12, color: Colors.green.shade700),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit_outlined,
                color: _brand,
              ),
              onPressed: onTap,
            ),
            SizedBox(
              width: 5.0
            ),
            IconButton(
              icon: Icon(Icons.delete_outline,
                color: _brand,
              ),
              onPressed: onDelete,
            ),
          ],
        )
      ),
    );
  }
}
