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

class KDBongkarOutDetailScreen extends StatefulWidget {
  final String noProcKD;
  final String tgl;
  final String tglKeluar;

  const KDBongkarOutDetailScreen({Key? key, required this.noProcKD, required this.tgl, required this.tglKeluar}) : super(key: key);

  @override
  State<KDBongkarOutDetailScreen> createState() => _KDBongkarOutDetailScreenState();
}

class _KDBongkarOutDetailScreenState extends State<KDBongkarOutDetailScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _locationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;

  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lokasiVM = Provider.of<LokasiViewModel>(context, listen: false);
      final kdDetailVM = Provider.of<KDBongkarDetailViewModel>(context, listen: false);

      lokasiVM.fetchLokasi();
      kdDetailVM.fetchBefore(widget.noProcKD);
      kdDetailVM.fetchAfter(widget.noProcKD);
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kdDetailVM = Provider.of<KDBongkarDetailViewModel>(context);
    final lokasiVM = Provider.of<LokasiViewModel>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildSimpleAppBar(kdDetailVM),
      body: Column(
        children: [
          _buildStatsAndFilter(kdDetailVM, lokasiVM),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSimpleList(kdDetailVM.beforeList, kdDetailVM.isLoading, "Semua label telah selesai di scan", isPending: true),
                _buildSimpleList(kdDetailVM.afterList, kdDetailVM.isLoading, "Belum ada label yang di scan", isPending: false),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  PreferredSizeWidget _buildSimpleAppBar(KDBongkarDetailViewModel kdDetailVM) {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF2E6F5D),
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.noProcKD,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: Container(
          color: const Color(0xFF2E6F5D),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 2,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Before (${kdDetailVM.totalBefore})"),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("After (${kdDetailVM.totalAfter})"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsAndFilter(KDBongkarDetailViewModel kdDetailVM, LokasiViewModel lokasiVM) {
    final total = kdDetailVM.totalBefore + kdDetailVM.totalAfter;
    final progress = total > 0 ? (kdDetailVM.totalAfter / total) : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Progress Circle
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E6F5D)),
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E6F5D),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Divider vertikal tipis biar ada pemisah
          Container(
            height: 40,
            width: 1,
            color: Colors.grey.shade300,
          ),

          const SizedBox(width: 20),

          // Location section
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Color(0xFF2E6F5D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSimpleDropdown(lokasiVM),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildSimpleDropdown(LokasiViewModel lokasiVM) {
    final suggestions = [
      SearchFieldListItem<String>('Semua'),
      ...lokasiVM.lokasiList.map((lok) => SearchFieldListItem<String>(lok.idLokasi)),
    ];

    return SearchField<String>(
      controller: _locationController,
      hint: 'Pilih Lokasi',
      searchInputDecoration: SearchInputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E6F5D)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
      ),
      suggestions: suggestions,
      onSuggestionTap: (selected) {
        setState(() {
          _selectedLocation = selected.searchKey;
          _locationController.text = selected.searchKey;
        });
      },
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

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPending ? Colors.orange.shade600 : Colors.green.shade600,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPending ? "PENDING" : "DONE",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8), // Space for expansion icon
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
              color: isPending ? Colors.green.shade50 : Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPending ? Icons.check_circle : Icons.pending_actions,
              size: 40,
              color: isPending ? Colors.green : Colors.orange,
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

  Widget _buildSpeedDial() {
    return SpeedDial(
      animatedIcon: AnimatedIcons.menu_close,
      backgroundColor: const Color(0xFF2E6F5D),
      foregroundColor: Colors.white,
      visible: true,
      spaceBetweenChildren: 16,
      overlayOpacity: 0.4,
      elevation: 8,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.qr_code_scanner),
          label: 'Scan QR Code',
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF2E6F5D),
          onTap: () {
            if (widget.tglKeluar != '-') {
              _showScanBarQRCode(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Belum keluar KD!'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  void _showScanBarQRCode(BuildContext context) {
    if (_selectedLocation == null || _selectedLocation!.toLowerCase().contains('semua')) {
      DialogError.show(
        context: context,
        title: 'Pilih Lokasi Terlebih Dahulu',
        message: 'Silakan pilih lokasi yang spesifik sebelum melakukan scan QR Code.',
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => BarcodeQrScanKdBongkarViewModel(),
          child: BarcodeQrScanKdBongkarScreen(
            noProcKD: widget.noProcKD,
            selectedLocation: _selectedLocation!,
          ),
        ),
      ),
    );
  }
}