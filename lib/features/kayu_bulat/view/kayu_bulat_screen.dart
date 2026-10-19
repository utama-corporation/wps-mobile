import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wps_mobile/core/utils/date_formatter.dart';
import '../view_model/kayu_bulat_view_model.dart';
import '../../../core/widgets/loading_skeleton.dart';
import 'kayu_bulat_attachment_screen.dart';

// ✅ SESUAIKAN path ini dengan lokasi AppInfoCard kamu
import '../../../core/widgets/app_info_card.dart'; // berisi AppInfoCard, InfoRowData

class KayuBulatScreen extends StatefulWidget {
  const KayuBulatScreen({super.key});

  @override
  State<KayuBulatScreen> createState() => _KayuBulatScreenState();
}

class _KayuBulatScreenState extends State<KayuBulatScreen> {
  static const Color _brand = Color(0xFF2E6F5D);

  @override
  void initState() {
    super.initState();
    // fetch data pertama kali setelah widget ter-load
    Future.microtask(
          () => Provider.of<KayuBulatViewModel>(context, listen: false).fetchAll(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Data Kayu Bulat",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _brand,
      ),
      body: Consumer<KayuBulatViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading && vm.list.isEmpty) {
            return const LoadingSkeleton();
          }

          if (vm.errorMessage.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(vm.errorMessage, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => vm.fetchAll(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Retry"),
                  )
                ],
              ),
            );
          }

          if (vm.list.isEmpty) {
            return const Center(child: Text("Tidak ada data kayu bulat."));
          }

          return RefreshIndicator(
            onRefresh: () => vm.fetchAll(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: vm.list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = vm.list[index];

                final isApproved = item.approve == 1;
                final statusText = isApproved ? "Approved" : "Pending";
                final statusColor = isApproved ? Colors.green : Colors.orange;

                return AppInfoCard(
                  title: item.noKayuBulat, // judul besar
                  subtitle: DateFormatter.fullFromYmd(context, item.dateCreate), // bisa ganti pakai formatter kalau mau
                  leadingIcon: Icons.assignment_outlined, // ikon besar di header
                  brandColor: _brand,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            KayuBulatAttachmentScreen(noKayuBulat: item.noKayuBulat),
                      ),
                    );
                  },
                  // contoh long-press (opsional): refresh item list
                  onLongPress: () => vm.fetchAll(),
                  rows: [
                    InfoRowData(
                      icon: Icons.badge_outlined,
                      label: "Suket",
                      value: item.suket,
                      color: const Color(0xFF658B81),
                    ),
                    InfoRowData(
                      icon: Icons.local_shipping_outlined,
                      label: "Truk",
                      value: "${item.noTruk} (${item.noPlat})",
                      color: Colors.blueGrey,
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
