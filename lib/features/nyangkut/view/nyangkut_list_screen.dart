import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/nyangkut_list_view_model.dart';
import '../view/nyangkut_detail_screen.dart';
import '../../../core/widgets/loading_skeleton.dart';

// ⬇️ reusable card dan row data
import '../../../core/widgets/app_info_card.dart';

class NyangkutListScreen extends StatelessWidget {
  const NyangkutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NyangkutListViewModel>(context, listen: false)
          .fetchNyangkutList();
    });

    const brandColor = Color(0xFF2E6F5D);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nyangkut List', style: TextStyle(color: Colors.white)),
        backgroundColor: brandColor,
      ),
      body: Consumer<NyangkutListViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.nyangkutList.isEmpty) {
            return const LoadingSkeleton();
          }

          if (vm.nyangkutList.isEmpty) {
            return _EmptyOrError(
              message: vm.errorMessage.isEmpty ? 'Tidak ada data' : vm.errorMessage,
              onRetry: vm.fetchNyangkutList,
            );
          }

          if (vm.errorMessage.isNotEmpty) {
            return _EmptyOrError(
              message: vm.errorMessage,
              onRetry: vm.fetchNyangkutList,
            );
          }

          return RefreshIndicator(
            onRefresh: () => vm.fetchNyangkutList(),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: vm.nyangkutList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final it = vm.nyangkutList[index];

                return AppInfoCard(
                  title: it.NoNyangkut.toString(),                 // judul besar
                  subtitle: 'Tanggal: ${it.tgl?.toString() ?? '-'}',
                  brandColor: brandColor,
                  leadingIcon: Icons.assignment_outlined,
                  // Jika butuh baris tambahan, tambahkan di rows
                  rows: [
                    // InfoRowData(
                    //   icon: Icons.calendar_today,
                    //   label: 'Tanggal',
                    //   value: it.tgl?.toString() ?? '-',            // pastikan String
                    //   color: Colors.blue.shade700,
                    // ),
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NyangkutDetailScreen(
                          noNyangkut: it.NoNyangkut.toString(),
                          tgl: it.tgl?.toString() ?? '-',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyOrError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _EmptyOrError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    const brandColor = Color(0xFF2E6F5D);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
