import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:searchfield/searchfield.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../../../core/view_models/lokasi_view_model.dart';
import '../view_model/kd_bongkar_detail_view_model.dart';
import '../view_model/barcode_qr_scan_kd_bongkar_view_model.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/dialog_error.dart';
import 'barcode_qr_scan_kd_bongkar_screen.dart';

class KDBongkarInDetailScreen extends StatefulWidget {
  final String noProcKD;
  final String tgl;
  final String tglKeluar;

  const KDBongkarInDetailScreen({Key? key, required this.noProcKD, required this.tgl, required this.tglKeluar}) : super(key: key);

  @override
  State<KDBongkarInDetailScreen> createState() => _KDBongkarInDetailScreenState();
}

class _KDBongkarInDetailScreenState extends State<KDBongkarInDetailScreen> {
  final TextEditingController _locationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kdDetailVM = Provider.of<KDBongkarDetailViewModel>(context, listen: false);
      kdDetailVM.fetchBefore(widget.noProcKD);
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kdDetailVM = Provider.of<KDBongkarDetailViewModel>(context);


    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildSimpleAppBar(kdDetailVM),
      body: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: _buildSimpleList(kdDetailVM.beforeList, kdDetailVM.isLoading, "Belum ada Label", isPending: true),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSimpleAppBar(KDBongkarDetailViewModel kdDetailVM) {
    final total = kdDetailVM.totalBefore;

    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF2E6F5D),
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${widget.noProcKD} ($total)",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleList(List<dynamic> list, bool isLoading, String emptyMessage, {required bool isPending}) {
    if (isLoading) return const LoadingSkeleton();

    if (list.isEmpty) {
      return _buildEmptyState(emptyMessage, isPending);
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildEnhancedItem(item, isPending, index);
      },
    );
  }

  // ENHANCED ITEM WIDGET - New improved version
  Widget _buildEnhancedItem(dynamic item, bool isPending, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.only(right: 10),
        childrenPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),

              // No ST
              Expanded(
                child: Text(
                  item.noST,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
        children: [
          // CONTENT SECTION - Hanya muncul ketika di-expand
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lokasi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.idLokasi != '-'
                                ? item.idLokasi
                                : (isPending ? "Menunggu lokasi" : "Tidak ada lokasi"),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: item.idLokasi == '-'
                                  ? (isPending ? Colors.orange.shade700 : Colors.grey.shade600)
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Label Info (if available)
                if (item.labelM3 != null || item.labelJumlah != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Row(
                            children: [
                              if (item.labelM3 != null) ...[
                                Text(
                                  'M³: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${item.labelM3}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (item.labelJumlah != null) const SizedBox(width: 16),
                              ],
                              if (item.labelJumlah != null) ...[
                                Text(
                                  'Qty: ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '${item.labelJumlah}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Detail Items Section (if available)
                if (item.details != null && item.details!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildDetailItemsSection(item.details!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // DETAIL ITEMS SECTION - New widget for showing detail items
  Widget _buildDetailItemsSection(List<dynamic> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.view_list,
              size: 18,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              'Detail Items (${details.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  'No.',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Dimensi (T×L×P)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  'Qty',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Table Content
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Column(
            children: details.asMap().entries.map((entry) {
              final index = entry.key;
              final detail = entry.value;
              final isLast = index == details.length - 1;

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                  border: isLast ? null : Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${detail.noUrut}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${detail.tebal} × ${detail.lebar} × ${detail.panjang}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${detail.jumlahBatang}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E6F5D),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, bool isPending) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2,
              size: 40,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}