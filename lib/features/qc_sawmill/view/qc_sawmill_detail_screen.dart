// lib/features/qc_sawmill/view/qc_sawmill_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../view_model/qc_sawmill_detail_view_model.dart';
import '../model/qc_sawmill_detail.dart';
import '../widgets/qc_detail_form_sheet.dart';
import '../widgets/qc_detail_item_card.dart';
import '../widgets/save_changes_sheet.dart';

class QcSawmillDetailScreen extends StatefulWidget {
  final String noQc;
  const QcSawmillDetailScreen({super.key, required this.noQc});

  @override
  State<QcSawmillDetailScreen> createState() => _QcSawmillDetailScreenState();
}

class _QcSawmillDetailScreenState extends State<QcSawmillDetailScreen> {
  final List<QcSawmillDetail> _drafts = [];
  final Set<int> _deletedKeys = <int>{};

  // Track renumbering: oldKey -> newKey
  final Map<int, int> _renumberingMap = {};

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF2E6F5D);

    return ChangeNotifierProvider(
      create: (_) => QcSawmillDetailViewModel()..load(widget.noQc),
      child: Consumer<QcSawmillDetailViewModel>(
        builder: (context, vm, _) {
          final hasError = vm.error.isNotEmpty;

          // Gabungkan saved + draft dalam satu list
          final rows = _buildUnifiedRows(vm);

          // Empty hanya jika tidak loading, tidak error, dan rows hasil gabungan kosong
          final showEmpty = !vm.isLoading && vm.error.isEmpty && rows.isEmpty;

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            appBar: AppBar(
              backgroundColor: brandColor,
              elevation: 0,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Detail QC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    vm.noQc,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            body: RefreshIndicator(
              color: brandColor,
              onRefresh: vm.refresh,
              child: vm.isLoading
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 200),
                  Center(child: CircularProgressIndicator(color: brandColor)),
                  const SizedBox(height: 200),
                ],
              )
                  : showEmpty
                  ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  EmptyState(
                    title: 'Belum ada detail',
                    subtitle: 'Tambahkan baris QC untuk memulai, atau tarik ke bawah untuk memuat ulang.',
                    icon: Icons.inbox_outlined,
                    maxContentWidth: 420,
                  ),
                  const SizedBox(height: 16),
                  _BottomButtons(
                    onAdd: () => _handleAddDraft(context, vm),
                    onSave: () => _handleSave(context, vm),
                    canSave: _drafts.isNotEmpty || _deletedKeys.isNotEmpty,
                    draftsCount: _drafts.length + _deletedKeys.length,
                  ),
                ],
              )
                  : _buildUnifiedList(vm, rows),
            ),

          );
        },
      ),
    );
  }

  /// Bangun list gabungan baris yang akan tampil (saved + drafts override)
  List<_RowVM> _buildUnifiedRows(QcSawmillDetailViewModel vm) {
    // 1) Terapkan renumbering map ke saved items (HANYA yang tidak dihapus)
    final savedMap = <int, QcSawmillDetail>{};
    for (final s in vm.items) {
      var k = s.noUrut;
      if (k == null) continue;

      // Skip yang ditandai hapus SEBELUM renumbering
      if (_deletedKeys.contains(k)) continue;

      // Jika item ini di-renumber, gunakan nomor baru
      if (_renumberingMap.containsKey(k)) {
        k = _renumberingMap[k]!;
      }

      savedMap[k] = s;
    }

    // 2) Index drafts
    final draftMap = <int, QcSawmillDetail>{};
    for (final d in _drafts) {
      final k = d.noUrut;
      if (k == null) continue;
      draftMap[k] = d;
    }

    // 3) Gabungkan keys dan urutkan
    final allKeys = <int>{...savedMap.keys, ...draftMap.keys}.toList()
      ..sort();

    // 4) Bangun rows dengan display index 1..N
    final rows = <_RowVM>[];
    for (var i = 0; i < allKeys.length; i++) {
      final k = allKeys[i];
      final displayIndex = i + 1;

      final hasSaved = savedMap.containsKey(k);
      final hasDraft = draftMap.containsKey(k);

      late QcSawmillDetail shown;
      bool isNew = false;
      bool isEdited = false;

      if (hasDraft && hasSaved) {
        // Ada draft DAN ada saved → Edit
        shown = draftMap[k]!;
        isEdited = true;
      } else if (hasDraft && !hasSaved) {
        // Ada draft tapi TIDAK ada saved → Baru
        shown = draftMap[k]!;
        isNew = true;
      } else {
        // Hanya saved (no draft)
        shown = savedMap[k]!;
      }

      rows.add(_RowVM(
        detail: shown,
        isNew: isNew,
        isEdited: isEdited,
        hasSaved: hasSaved,
        displayIndex: displayIndex,
        actualKey: k,
      ));
    }

    return rows;
  }

  Widget _buildUnifiedList(QcSawmillDetailViewModel vm, List<_RowVM> rows) {
    final showErrorBanner = vm.error.isNotEmpty;
    final totalCount = (showErrorBanner ? 1 : 0) + rows.length + 1;

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: totalCount,
      itemBuilder: (ctx, rawIndex) {
        var i = rawIndex;

        // Banner error
        if (showErrorBanner) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ErrorState(
                title: 'Terjadi kesalahan',
                message: vm.error,
                // bikin lebih kompak untuk “banner”
                maxContentWidth: 600,
                primaryAction: TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat ulang'),
                  onPressed: vm.refresh,
                ),
              ),
            );
          }
          i -= 1;
        }

        // Baris data
        if (i < rows.length) {
          final row = rows[i];

          return QcDetailItemBlendCard(
            detail: row.detail,
            isNew: row.isNew,
            isEdited: row.isEdited,
            displayIndex: row.displayIndex,
            onEdit: () => _handleEdit(context, vm, row, rows),
            onDelete: () => _handleDelete(context, row),
          );
        }

        // Bottom buttons
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: _BottomButtons(
            onAdd: () => _handleAddDraft(context, vm),
            onSave: () => _handleSave(context, vm),
            canSave: _drafts.isNotEmpty || _deletedKeys.isNotEmpty,
            draftsCount: _drafts.length + _deletedKeys.length,
          ),
        );
      },
    );
  }

  // ---------- Actions ----------
  Future<void> _handleEdit(
      BuildContext context,
      QcSawmillDetailViewModel vm,
      _RowVM row,
      List<_RowVM> currentRows,
      ) async {
    final noUrut = row.actualKey;

    // Batalkan delete jika baris ini sempat ditandai
    if (_deletedKeys.contains(noUrut)) {
      setState(() => _deletedKeys.remove(noUrut));
    }

    final updated = await showQcDetailFormSheet(
      context,
      initial: row.detail,
      suggestedNoUrut: row.displayIndex,
    );
    if (updated == null) return;

    setState(() {
      // Hapus draft lama jika ganti key
      if (updated.noUrut != noUrut) {
        _drafts.removeWhere((d) => d.noUrut == noUrut);
        if (updated.noUrut != null) {
          _deletedKeys.remove(updated.noUrut);
        }
      }

      // Upsert draft baru
      _drafts.removeWhere((d) => d.noUrut == updated.noUrut);
      _drafts.add(updated);
      if (updated.noUrut != null) {
        _deletedKeys.remove(updated.noUrut);
      }
    });

    AppToast.info(
      context,
      row.hasSaved ? 'Edit ditambahkan ke draft' : 'Draft baru diperbarui',
    );  }

  void _handleDelete(BuildContext context, _RowVM row) {
    final noUrut = row.actualKey;

    setState(() {
      if (!row.hasSaved) {
        // Draft baru → hapus dari list
        _drafts.removeWhere((x) => x.noUrut == noUrut);
        AppToast.success(context, 'Draft dihapus');
      } else {
        // Data tersimpan → tandai delete
        _drafts.removeWhere((d) => d.noUrut == noUrut);
        _deletedKeys.add(noUrut);
        AppToast.success(context, 'Baris ditandai untuk dihapus');

      }
    });
  }

  Future<void> _handleAddDraft(BuildContext context, QcSawmillDetailViewModel vm) async {
    final currentRows = _buildUnifiedRows(vm);

    // Cari key yang benar-benar tidak terpakai (termasuk yang dihapus)
    final usedKeys = <int>{};

    // Keys dari saved items (semua, termasuk yang dihapus)
    for (final s in vm.items) {
      if (s.noUrut != null) usedKeys.add(s.noUrut!);
    }

    // Keys dari drafts
    for (final d in _drafts) {
      if (d.noUrut != null) usedKeys.add(d.noUrut!);
    }

    // Cari key terkecil yang belum dipakai
    int nextNo = 1;
    while (usedKeys.contains(nextNo)) {
      nextNo++;
    }

    final result = await showQcDetailFormSheet(
      context,
      initial: QcSawmillDetail(noQc: vm.noQc, noUrut: nextNo),
      suggestedNoUrut: nextNo,
    );
    if (result == null) return;

    setState(() {
      _drafts.removeWhere((d) => d.noUrut == result.noUrut);
      _drafts.add(result);
      if (result.noUrut != null) {
        _deletedKeys.remove(result.noUrut);
      }
    });

    AppToast.success(context, 'Draft baru ditambahkan');
  }

  Future<void> _handleSave(BuildContext context, QcSawmillDetailViewModel vm) async {
    // Tidak ada perubahan sama sekali → abaikan
    if (_drafts.isEmpty && _deletedKeys.isEmpty) return;

    // Konfirmasi via bottom sheet
    final confirm = await showConfirmSaveSheet(
      context,
      draftsCount: _drafts.length,
      deletedCount: _deletedKeys.length,
      brandColor: const Color(0xFF2E6F5D),
    );
    if (!confirm) return;

    // Susun payload akhir seperti biasa
    final payload = _prepareSavePayload(vm);

    // Jika payload kosong → deleteAll, else replaceAll
    final bool ok = payload.isEmpty ? await vm.deleteAll() : await vm.replaceAll(payload);
    if (!mounted) return;


    if (ok) {
      setState(() {
        _drafts.clear();
        _deletedKeys.clear();
        _renumberingMap.clear();
      });

      if (payload.isEmpty) {
        // tidak ada detail tersisa → pakai info
        AppToast.info(context, 'Semua detail dihapus');
      } else {
        // ada perubahan yang tersimpan → sukses
        AppToast.success(context, 'Berhasil menyimpan');
      }
    } else {
      // gagal simpan → error
      AppToast.error(context, vm.error.isEmpty ? 'Gagal menyimpan' : vm.error);
    }

  }


  /// Persiapkan payload final dengan noUrut 1..N
  List<QcSawmillDetail> _prepareSavePayload(QcSawmillDetailViewModel vm) {
    // 1) Ambil semua saved items (kecuali yang dihapus)
    final savedMap = <int, QcSawmillDetail>{};
    for (final s in vm.items) {
      final k = s.noUrut;
      if (k == null) continue;
      if (_deletedKeys.contains(k)) continue;
      savedMap[k] = s;
    }

    // 2) Override dengan drafts
    final draftMap = <int, QcSawmillDetail>{};
    for (final d in _drafts) {
      final k = d.noUrut;
      if (k == null) continue;
      if (_deletedKeys.contains(k)) continue;
      draftMap[k] = d;
    }

    // 3) Merge
    final byKey = <int, QcSawmillDetail>{...savedMap};
    for (final entry in draftMap.entries) {
      byKey[entry.key] = entry.value;
    }

    // 4) Urutkan berdasarkan noUrut
    final sorted = byKey.values.toList()
      ..sort((a, b) => (a.noUrut ?? 0).compareTo(b.noUrut ?? 0));

    // 5) Renumber menjadi 1..N
    final result = <QcSawmillDetail>[];
    for (var i = 0; i < sorted.length; i++) {
      final item = sorted[i];
      final newNo = i + 1;

      result.add(QcSawmillDetail(
        noQc: item.noQc,
        noUrut: newNo,
        cuttingTebal: item.cuttingTebal,
        cuttingLebar: item.cuttingLebar,
        actualTebal: item.actualTebal,
        actualLebar: item.actualLebar,
        susutTebal: item.susutTebal,
        susutLebar: item.susutLebar,
      ));
    }

    return result;
  }

}

// ---------- VM untuk 1 baris gabungan ----------
class _RowVM {
  final QcSawmillDetail detail;
  final bool isNew;
  final bool isEdited;
  final bool hasSaved;
  final int displayIndex; // Nomor tampil 1..N
  final int actualKey;    // Key asli di map

  _RowVM({
    required this.detail,
    required this.isNew,
    required this.isEdited,
    required this.hasSaved,
    required this.displayIndex,
    required this.actualKey,
  });
}


class _BottomButtons extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onSave;
  final bool canSave;
  final int draftsCount;

  const _BottomButtons({
    required this.onAdd,
    required this.onSave,
    required this.canSave,
    required this.draftsCount,
  });

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF2E6F5D);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Tambah Baris'),
            style: OutlinedButton.styleFrom(
              foregroundColor: brandColor,
              side: const BorderSide(color: brandColor, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onAdd,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            icon: const Icon(Icons.save),
            label: Text(canSave ? 'Simpan ($draftsCount)' : 'Simpan'),
            style: FilledButton.styleFrom(
              backgroundColor: brandColor,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: canSave ? onSave : null,
          ),
        ),
      ],
    );
  }
}
