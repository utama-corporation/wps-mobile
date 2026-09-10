// lib/features/qc_spk_bj/view/qc_spk_header_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/app_info_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../model/qc_spk_header.dart';
import '../view_model/qc_spk_header_view_model.dart';
import 'qc_spk_line_screen.dart';

const _brand = Color(0xFF755330);

class QcSpkHeaderScreen extends StatefulWidget {
  const QcSpkHeaderScreen({super.key});

  @override
  State<QcSpkHeaderScreen> createState() => _QcSpkHeaderScreenState();
}

class _QcSpkHeaderScreenState extends State<QcSpkHeaderScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<QcSpkHeaderViewModel>().refreshFirstPage();
      _scrollCtrl.addListener(() {
        final vm = context.read<QcSpkHeaderViewModel>();
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
    return Consumer<QcSpkHeaderViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          appBar: AppBar(
            backgroundColor: _brand,
            elevation: 0,
            toolbarHeight: 64,
            title: const Text(
              'Pilih SPK untuk QC',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                tooltip: 'Cari',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => ChangeNotifierProvider.value(
                        value: vm,
                        child: const _SpkSearchPage(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            color: _brand,
            onRefresh: () => vm.refreshFirstPage(),
            child: Builder(
              builder: (_) {
                if (vm.error.isNotEmpty && vm.items.isEmpty) {
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
                        title: 'Belum ada SPK',
                        subtitle: 'Tidak ada SPK aktif yang bisa di-QC',
                        icon: Icons.inbox_outlined,
                      ),
                      SizedBox(height: 24),
                    ],
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  itemCount: vm.items.length + (vm.canLoadMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i >= vm.items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: CircularProgressIndicator(color: _brand),
                        ),
                      );
                    }
                    return _SpkCard(item: vm.items[i]);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _SpkCard extends StatelessWidget {
  final QcSpkHeader item;
  const _SpkCard({required this.item});

  static const _maxProdukShown = 3;

  String _produkValue() {
    if (item.lines.isEmpty) {
      return item.totalLine > 0 ? '${item.totalLine} baris' : '-';
    }
    final shown =
        item.lines.take(_maxProdukShown).map((e) => e.pendek).join(', ');
    final sisa = item.lines.length - _maxProdukShown;
    return sisa > 0 ? '$shown +$sisa lainnya' : shown;
  }

  String _buyerTujuan() {
    final parts = <String>[];
    if ((item.namaBuyer ?? '').trim().isNotEmpty)
      parts.add(item.namaBuyer!.trim());
    if ((item.tujuan ?? '').trim().isNotEmpty) parts.add(item.tujuan!.trim());
    return parts.isEmpty ? '-' : parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final rows = <InfoRowData>[
      InfoRowData(
        icon: Icons.local_shipping_outlined,
        label: 'Tujuan',
        value: _buyerTujuan(),
        color: Colors.green.shade700,
      ),
      InfoRowData(
        icon: Icons.description_outlined,
        label: 'No Contract',
        value: (item.noContract ?? '').trim().isEmpty
            ? '-'
            : item.noContract!.trim(),
        color: Colors.blue.shade700,
      ),
      InfoRowData(
        icon: Icons.category_outlined,
        label: 'Produk',
        value: _produkValue(),
        color: Colors.deepPurple.shade400,
      ),
    ];

    return AppInfoCard(
      title: item.noSPK,
      subtitle: DateFormatter.fullFromYmd(context, item.tanggal),
      brandColor: _brand,
      leadingIcon: Icons.assignment_outlined,
      rows: rows,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QcSpkLineScreen(noSPK: item.noSPK),
          ),
        );
      },
    );
  }
}

/// ================== Search Page ==================
class _SpkSearchPage extends StatefulWidget {
  const _SpkSearchPage();

  @override
  State<_SpkSearchPage> createState() => _SpkSearchPageState();
}

class _SpkSearchPageState extends State<_SpkSearchPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  DateTime _lastType = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(() {
      final vm = context.read<QcSpkHeaderViewModel>();
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
    final vm = context.read<QcSpkHeaderViewModel>();
    vm.setSearch(q.trim());
    vm.refreshFirstPage();
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
              hintText: 'Cari No SPK, Buyer, No Contract, Tujuan...',
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
                if (DateTime.now().difference(_lastType).inMilliseconds >=
                    240) {
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
      body: Consumer<QcSpkHeaderViewModel>(
        builder: (context, vm, _) {
          if (vm.error.isNotEmpty && vm.items.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 48, bottom: 24),
              children: [ErrorState(message: vm.error)],
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: vm.items.length + (vm.canLoadMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i >= vm.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _SpkCard(item: vm.items[i]);
            },
          );
        },
      ),
    );
  }
}
