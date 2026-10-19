// lib/features/qc_sawmill/view/qc_sawmill_header_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_info_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../view_model/qc_sawmill_header_view_model.dart';
import '../model/qc_sawmill_header.dart';
import '../widgets/confirm_dialog.dart';
import 'qc_sawmill_detail_screen.dart';
import './../widgets/qc_header_form_sheet.dart';
import '../widgets/qc_header_row_actions_sheet.dart';

class QcSawmillHeaderScreen extends StatefulWidget {
  const QcSawmillHeaderScreen({super.key});

  @override
  State<QcSawmillHeaderScreen> createState() => _QcSawmillHeaderScreenState();
}

class _QcSawmillHeaderScreenState extends State<QcSawmillHeaderScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<QcSawmillHeaderViewModel>();
      vm.refreshFirstPage();

      _scrollCtrl.addListener(() {
        final vm = context.read<QcSawmillHeaderViewModel>();
        if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200) {
          vm.loadNextPage();
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF2E6F5D);

    return Consumer<QcSawmillHeaderViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          // 🎨 AppBar modern dengan summary
          appBar: AppBar(
            backgroundColor: brandColor,
            elevation: 0,
            toolbarHeight: 64,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'QC Sawmill',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              // Search button dengan background
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  tooltip: 'Cari',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => const _QcSearchPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          body: RefreshIndicator(
            color: brandColor,
            onRefresh: () => vm.refreshFirstPage(),
            child: Builder(
              builder: (_) {
                if (vm.error.isNotEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 48),
                      ErrorState(
                        message: 'Terjadi kesalahan saat memuat data.',
                      ),
                      SizedBox(height: 24),
                    ],
                  );
                }

                if (!vm.isLoading && vm.items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 48),
                      EmptyState(
                        title: 'Belum ada data',
                        subtitle: 'Tap tombol + di bawah untuk menambah data baru',
                        icon: Icons.inbox_outlined,
                      ),
                      SizedBox(height: 24),
                    ],
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: vm.items.length + (vm.canLoadMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i >= vm.items.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: brandColor,
                          ),
                        ),
                      );
                    }

                    final QcSawmillHeader it = vm.items[i];

                    return AppInfoCard(
                      title: it.noQc,
                      subtitle: DateFormatter.fullFromYmd(context, it.tgl),
                      brandColor: brandColor,
                      leadingIcon: Icons.assignment_outlined,
                      rows: [
                        InfoRowData(
                          icon: Icons.category_outlined,
                          label: 'Jenis Kayu',
                          value: it.namaJenisKayu ?? '-',
                          color: Colors.blue.shade700,
                        ),
                        InfoRowData(
                          icon: Icons.table_restaurant_outlined,
                          label: 'Meja',
                          value: it.namaMeja?.toString() ?? '-',
                          color: Colors.green.shade700,
                        ),
                      ],
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => QcSawmillDetailScreen(noQc: it.noQc),
                          ),
                        );
                      },
                      onLongPress: () async {
                        final action = await showQcHeaderRowActionsSheet(context, row: it);
                        if (action == null) return;
                        final mapped = (action == QcRowAction.edit) ? _RowAction.edit : _RowAction.delete;
                        final parentVm = context.read<QcSawmillHeaderViewModel>();
                        await handleRowActionCommon(context, parentVm, it, mapped);
                      },
                    );
                  },
                );
              },
            ),
          ),
          // 🎨 FAB dengan shadow
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: brandColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              backgroundColor: brandColor,
              elevation: 0,
              onPressed: () async {
                final created = await showQcHeaderFormSheet(context);
                if (created == true && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 10),
                          Text('Header berhasil dibuat'),
                        ],
                      ),
                      backgroundColor: Colors.green.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Tambah',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ================== Search Page ==================

class _QcSearchPage extends StatefulWidget {
  const _QcSearchPage();

  @override
  State<_QcSearchPage> createState() => _QcSearchPageState();
}

class _QcSearchPageState extends State<_QcSearchPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<String> _history = <String>[];
  DateTime _lastType = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final vm = context.read<QcSawmillHeaderViewModel>();
      if (_scrollCtrl.position.pixels >=
          _scrollCtrl.position.maxScrollExtent - 200) {
        vm.loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _applySearch(String q) {
    final vm = context.read<QcSawmillHeaderViewModel>();
    vm.setSearch(q.trim());
    vm.refreshFirstPage();

    if (q.trim().isNotEmpty) {
      setState(() {
        _history.removeWhere((e) => e.toLowerCase() == q.trim().toLowerCase());
        _history.insert(0, q.trim());
        if (_history.length > 8) _history.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Cari No QC, Jenis Kayu, atau Meja...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () {
                  _searchCtrl.clear();
                  _applySearch('');
                  setState(() {});
                },
              )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: _applySearch,
            onChanged: (text) {
              setState(() {});
              _lastType = DateTime.now();
              Future.delayed(const Duration(milliseconds: 250)).then((_) {
                final diff = DateTime.now().difference(_lastType);
                if (diff.inMilliseconds >= 240) {
                  _applySearch(text);
                }
              });
            },
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Colors.grey[200]),
        ),
      ),
      body: Consumer<QcSawmillHeaderViewModel>(
        builder: (context, vm, _) {
          final showSuggestion =
              !vm.isLoading && vm.items.isEmpty && (_searchCtrl.text.isEmpty);

          if (showSuggestion && _history.isNotEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Icon(Icons.history, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Pencarian Terbaru',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._history.map((h) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    leading: Icon(Icons.search,
                        size: 20,
                        color: Colors.grey[600]),
                    title: Text(
                      h,
                      style: const TextStyle(fontSize: 14),
                    ),
                    trailing: Icon(Icons.north_west,
                        size: 16,
                        color: Colors.grey[400]),
                    onTap: () {
                      _searchCtrl.text = h;
                      _applySearch(h);
                    },
                  ),
                )),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _history.clear()),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Hapus Histori'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
              ],
            );
          }

          if (vm.error.isNotEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 48, bottom: 24),
              children: [
                ErrorState(
                  message: vm.error,
                  primaryAction: FilledButton.tonal(
                    onPressed: vm.isLoading ? null : vm.refreshFirstPage,
                    child: const Text('Coba lagi'),
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
                  title: 'Tidak ditemukan',
                  subtitle: 'Coba kata kunci lain atau periksa ejaan',
                  icon: Icons.search_off,
                ),
                SizedBox(height: 24),
              ],
            );
          }

          return ListView.builder(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: vm.items.length + (vm.canLoadMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i >= vm.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final QcSawmillHeader it = vm.items[i];

              return AppInfoCard(
                title: it.noQc,
                subtitle: DateFormatter.fullFromYmd(context, it.tgl),
                leadingIcon: Icons.assignment_outlined,
                rows: [
                  InfoRowData(
                    icon: Icons.category_outlined,
                    label: 'Jenis Kayu',
                    value: it.namaJenisKayu ?? '-',
                    color: Colors.blue.shade700,
                  ),
                  InfoRowData(
                    icon: Icons.table_bar_outlined,
                    label: 'Meja',
                    value: it.meja?.toString() ?? '-',
                    color: Colors.green.shade700,
                  ),
                ],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => QcSawmillDetailScreen(noQc: it.noQc),
                    ),
                  );
                },
                onLongPress: () async {
                  final action = await showQcHeaderRowActionsSheet(context, row: it);
                  if (action == null) return;
                  final mapped = (action == QcRowAction.edit) ? _RowAction.edit : _RowAction.delete;
                  final parentVm = context.read<QcSawmillHeaderViewModel>();
                  await handleRowActionCommon(context, parentVm, it, mapped);
                },
              );
            },
          );
        },
      ),
    );
  }
}

enum _RowAction { edit, delete }


/// ====== Helper functions ======

Future<void> handleRowActionCommon(
    BuildContext context,
    QcSawmillHeaderViewModel vm,
    QcSawmillHeader row,
    _RowAction action,
    ) async {
  switch (action) {
    case _RowAction.edit:
      final changed = await showQcHeaderFormSheet(context, initial: row);
      if (!context.mounted) return;
      if (changed == true) {
        await vm.loadPage(vm.meta?.page ?? 1);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Data berhasil diperbarui'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      break;

    case _RowAction.delete:
      final ok = await confirmDeleteCommon(context, row.noQc);
      if (ok != true) return;

      final success = await vm.deleteByNoQc(row.noQc);
      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_outline, color: Colors.white),
                const SizedBox(width: 10),
                Text('Berhasil hapus ${row.noQc}'),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        vm.loadPage(vm.meta?.page ?? 1);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal hapus ${row.noQc}: ${vm.error}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      break;
  }
}

Future<bool?> confirmDeleteCommon(BuildContext context, String noQc) {
  return showDeleteQcHeaderConfirm(context, noQc: noQc);
}