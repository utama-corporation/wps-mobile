import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/view_models/lokasi_view_model.dart';
import '../../../features/nyangkut/view_model/nyangkut_detail_view_model.dart';
import '../../../core/widgets/loading_skeleton.dart';
import 'package:searchfield/searchfield.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'barcode_qr_scan_nyangkut_screen.dart';



class NyangkutDetailScreen extends StatefulWidget {
  final String noNyangkut;
  final String tgl;

  const NyangkutDetailScreen({Key? key, required this.noNyangkut, required this.tgl}) : super(key: key);

  @override
  _NyangkutDetailScreenState createState() => _NyangkutDetailScreenState();
}

class _NyangkutDetailScreenState extends State<NyangkutDetailScreen> {
  final TextEditingController _locationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedFilter;
  String? _selectedLocation;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final lokasiVM = Provider.of<LokasiViewModel>(context, listen: false);
      final nyangkutVM = Provider.of<NyangkutDetailViewModel>(context, listen: false);

      lokasiVM.fetchLokasi();
      nyangkutVM.fetchInitialData(widget.noNyangkut); // 👈 Gunakan method baru
    });

    _scrollController.addListener(() {
      final nyangkutVM = Provider.of<NyangkutDetailViewModel>(context, listen: false);
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100 &&
          !nyangkutVM.isLoading &&
          nyangkutVM.hasMoreData) {
        nyangkutVM.loadMoreData(widget.noNyangkut); // 👈 Gunakan loadMore
      }
    });
  }


  @override
  void dispose() {
    _scrollController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nyangkutVM = Provider.of<NyangkutDetailViewModel>(context);
    final lokasiVM = Provider.of<LokasiViewModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tgl} ( ${widget.noNyangkut} )', style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E6F5D),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildFilterDropdown(nyangkutVM),
                const SizedBox(width: 16),
                _buildLocationDropdown(lokasiVM, nyangkutVM),
                const SizedBox(width: 16),
                Text('${nyangkutVM.totalData} Label',
                  style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),),
              ],
            ),
          ),
          Expanded(
            child: nyangkutVM.isInitialLoading
                ? const LoadingSkeleton() // loading awal
                : nyangkutVM.labelList.isEmpty
                ? const Center(child: Text('Tidak ada data'))
                : ListView.builder(
              controller: _scrollController,
              itemCount: nyangkutVM.labelList.length + (nyangkutVM.hasMoreData ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == nyangkutVM.labelList.length) {
                  // Ini baris loading tambahan (load more)
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final item = nyangkutVM.labelList[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.combinedLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            item.dateCreate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        item.labelType.isNotEmpty ? item.labelType : 'Tidak Ada Tipe',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        'Lokasi: ${item.labelLocation.isNotEmpty ? item.labelLocation : "-"}',
                        style: const TextStyle(fontSize: 14, color: Colors.blueAccent),
                      ),
                      const Divider(),
                    ],
                  ),
                );
              },
            ),
          )

        ],
      ),

      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: const Color(0xFF2E6F5D),
        foregroundColor: Colors.white,
        visible: true,
        curve: Curves.linear,
        spaceBetweenChildren: 16,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.qr_code),
            label: 'Scan QR',
            onTap: () {
              _showScanBarQRCode(context);
            },
          ),
          // SpeedDialChild(
          //   child: const Icon(Icons.edit_note),
          //   label: 'Input Manual',
          //   onTap: () {
          //     // _showAddManualDialog(context);
          //   },
          // ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(NyangkutDetailViewModel nyangkutVM) {
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        hint: const Text('Filter Label'),
        isExpanded: true,
        onChanged: (value) {
          setState(() {
            _selectedFilter = value;
          });
          nyangkutVM.fetchInitialData(
            widget.noNyangkut,
            filterBy: _selectedFilter,
            idLokasi: _selectedLocation == 'Semua' ? null : _selectedLocation,
          );
        },


        items: const [
          DropdownMenuItem(value: null, child: Text('Semua')),
          DropdownMenuItem(value: 'st', child: Text('ST')),
          DropdownMenuItem(value: 's4s', child: Text('S4S')),
          DropdownMenuItem(value: 'fj', child: Text('FJ')),
          DropdownMenuItem(value: 'moulding', child: Text('MLD')),
          DropdownMenuItem(value: 'laminating', child: Text('LMT')),
          DropdownMenuItem(value: 'ccakhir', child: Text('CCA')),
          DropdownMenuItem(value: 'sanding', child: Text('SND')),
          DropdownMenuItem(value: 'bj', child: Text('BJ')),
        ],
        underline: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildLocationDropdown(LokasiViewModel lokasiVM, NyangkutDetailViewModel nyangkutVM) {
    final suggestions = [
       SearchFieldListItem<String>('Semua'),
      ...lokasiVM.lokasiList.map(
            (lok) => SearchFieldListItem<String>(lok.idLokasi),
      ),
    ];

    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SearchField<String>(
        controller: _locationController,
        hint: 'Lokasi',
        searchInputDecoration:  SearchInputDecoration(border: InputBorder.none),
        suggestions: suggestions,
        onSuggestionTap: (selected) {
          setState(() {
            _selectedLocation = selected.searchKey;
            _locationController.text = selected.searchKey;
          });
          nyangkutVM.fetchInitialData(
            widget.noNyangkut,
            filterBy: _selectedFilter,
            idLokasi: _selectedLocation == 'Semua' ? null : _selectedLocation,
          );
        },


      ),
    );
  }

  void _showScanBarQRCode(BuildContext context) {


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeQrScanNyangkutScreen(
          noNyangkut: widget.noNyangkut,
          selectedFilter: _selectedFilter ?? 'all',
        ),
      ),
    );
  }
}
