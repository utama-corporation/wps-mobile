import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'kd_bongkar_out_detail_screen.dart';
import '../view_model/kd_bongkar_view_model.dart';
import '../../../core/widgets/loading_skeleton.dart';

// ⬇️ reusable card
import '../../../core/widgets/app_info_card.dart';

class KdBongkarOutScreen extends StatelessWidget {
  const KdBongkarOutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<KDBongkarViewModel>(context, listen: false)
          .fetchKDBongkarList(isPending: false);
    });

    const brandColor = Color(0xFF2E6F5D);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KD Out', style: TextStyle(color: Colors.white)),
        backgroundColor: brandColor,
      ),
      body: Consumer<KDBongkarViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading && vm.kdBongkarList.isEmpty) {
            return const LoadingSkeleton();
          }

          if (vm.kdBongkarList.isEmpty) {
            return _EmptyOrError(
              message: vm.errorMessage.isEmpty ? 'Tidak ada data' : vm.errorMessage,
              onRetry: () => vm.fetchKDBongkarList(isPending: false),
            );
          }

          if (vm.errorMessage.isNotEmpty) {
            return _EmptyOrError(
              message: vm.errorMessage,
              onRetry: () => vm.fetchKDBongkarList(isPending: false),
            );
          }

          return RefreshIndicator(
            onRefresh: () => vm.fetchKDBongkarList(isPending: false),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: vm.kdBongkarList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final it = vm.kdBongkarList[index];

                // Mapping ke AppInfoCard
                return AppInfoCard(
                  title: it.noProcKD,                     // judul besar
                  brandColor: brandColor,
                  leadingIcon: Icons.assignment_outlined,
                  rows: [
                    InfoRowData(
                      icon: Icons.confirmation_number_outlined,
                      label: 'No. KD',
                      value: it.noRuangKD.toString() ?? '-',   // ⬅️ penting
                      color: Colors.blue.shade700,
                    ),
                    InfoRowData(
                      icon: Icons.login,
                      label: 'Tgl Masuk',
                      value: '${it.tglMasuk}',
                      color: Colors.green.shade700,
                    ),
                    InfoRowData(
                      icon: Icons.logout,
                      label: 'Tgl Keluar',
                      value: '${it.tglKeluar ?? '-'}',
                      color: Colors.red.shade700,
                    ),
                  ],
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KDBongkarOutDetailScreen(
                          noProcKD: it.noProcKD,
                          tgl: it.tglMasuk,
                          tglKeluar: it.tglKeluar?.toString() ?? '-',
                        ),
                      ),
                    );
                  },
                  onLongPress: () {
                    // opsional: aksi long-press (hapus/edit, dll)
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
