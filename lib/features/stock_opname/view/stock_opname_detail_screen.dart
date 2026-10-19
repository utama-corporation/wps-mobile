import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../view_model/stock_opname_detail_view_model.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../widget/add_manual_dialog.dart';
import 'barcode_qr_scan_stock_opname_screen.dart';
import 'package:searchfield/searchfield.dart';
import 'package:flutter_searchable_dropdown/flutter_searchable_dropdown.dart'; // Import package

class StockOpnameInputScreen extends StatefulWidget {
  final String noSO;
  final String tgl;

  const StockOpnameInputScreen(
      {Key? key, required this.noSO, required this.tgl})
      : super(key: key);

  @override
  _StockOpnameInputScreenState createState() => _StockOpnameInputScreenState();
}

class _StockOpnameInputScreenState extends State<StockOpnameInputScreen> {
  final TextEditingController _locationController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedFilter;
  String? _selectedLocation;
  bool isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final viewModel =
        Provider.of<StockOpnameInputViewModel>(context, listen: false);

    // Memanggil fetchData() untuk memuat data lokasi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      viewModel.fetchData(widget.noSO).then((_) {
        setState(() {});
      });
    });

    // Menambahkan listener untuk infinite scroll
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        if (!isLoadingMore) {
          isLoadingMore = true;
          viewModel.loadMoreData(widget.noSO).then((_) {
            isLoadingMore = false;
          });
        }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.tgl} ( ${widget.noSO} )',
          style: const TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF2E6F5D),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildFilterDropdown(),
                SizedBox(width: 16),
                _buildLocationDropdown(), // Menggunakan SearchableDropdown
                SizedBox(width: 16),
                _buildCountText(), // Menampilkan count di sebelah kanan
              ],
            ),
          ),
          Expanded(
            child: Consumer<StockOpnameInputViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isInitialLoading &&
                    viewModel.noLabelList.isEmpty) {
                  return const LoadingSkeleton();
                }

                if (viewModel.errorMessage.isNotEmpty) {
                  return Center(
                    child: Text(
                      viewModel.errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  );
                }

                if (!viewModel.noLabelFound) {
                  return const Center(
                    child: Text(
                      'Data Tidak Ditemukan',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: viewModel.noLabelList.length +
                      (viewModel.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == viewModel.noLabelList.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final noLabel = viewModel.noLabelList[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 0.0, horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            noLabel.combinedLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            noLabel.labelType ?? 'Tidak Ada Tipe',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                          ),
                          Text(
                            'Lokasi: ${noLabel.labelLocation ?? "-"}',
                            style: const TextStyle(
                                fontSize: 14, color: Colors.blueAccent),
                          ),
                          const Divider(),
                        ],
                      ),
                    );
                  },
                  cacheExtent: 1000,
                );
              },
            ),
          ),
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
          SpeedDialChild(
            child: const Icon(Icons.edit_note),
            label: 'Input Manual',
            onTap: () {
              _showAddManualDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: 120, // Tentukan lebar dropdown
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButton<String>(
        value: _selectedFilter,
        hint: const Text('Filter Label'),
        isExpanded: true, // Agar dropdown mengisi ruang lebar yang tersedia
        onChanged: (value) {
          setState(() {
            _selectedFilter = value;
          });

          final viewModel =
              Provider.of<StockOpnameInputViewModel>(context, listen: false);
          viewModel.fetchData(widget.noSO,
              filterBy: _selectedFilter, idLokasi: _selectedLocation);
        },
        items: [
          DropdownMenuItem<String>(value: null, child: Text('Semua')),
          DropdownMenuItem<String>(value: 'st', child: Text('ST')),
          DropdownMenuItem<String>(value: 's4s', child: Text('S4S')),
          DropdownMenuItem<String>(value: 'fj', child: Text('FJ')),
          DropdownMenuItem<String>(value: 'moulding', child: Text('MLD')),
          DropdownMenuItem<String>(value: 'laminating', child: Text('LMT')),
          DropdownMenuItem<String>(value: 'ccakhir', child: Text('CCA')),
          DropdownMenuItem<String>(value: 'sanding', child: Text('SND')),
          DropdownMenuItem<String>(value: 'bj', child: Text('BJ')),
          // DropdownMenuItem<String>(value: 'kayubulat', child: Text('KB')),
        ],
        underline: SizedBox.shrink(), // Menghilangkan garis bawah yang default
      ),
    );
  }

  Widget _buildLocationDropdown() {
    return Container(
      width: 120, // Tentukan lebar tetap untuk dropdown
      padding: EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: SearchField(
        controller:
            _locationController, // Menghubungkan controller dengan SearchField
        hint: 'Lokasi',
        searchInputDecoration: SearchInputDecoration(
          border: InputBorder.none,
        ),
        suggestions: [
          // Menambahkan "Semua" sebagai item pertama
          SearchFieldListItem('Semua'),
          // Menambahkan lokasi-lokasi lainnya setelah "Semua"
          ...Provider.of<StockOpnameInputViewModel>(context, listen: false)
              .blokList
              .map((lokasi) => SearchFieldListItem(lokasi.idLokasi))
              .toList(),
        ],
        onSuggestionTap: (selectedLocation) {
          setState(() {
            _selectedLocation =
                selectedLocation.searchKey; // Menyimpan ID Lokasi
            _locationController.text =
                selectedLocation.searchKey; // Menampilkan nama lokasi di input
          });

          final viewModel =
              Provider.of<StockOpnameInputViewModel>(context, listen: false);
          if (_selectedLocation == 'Semua') {
            viewModel.fetchData(widget.noSO,
                filterBy: _selectedFilter, idLokasi: null);
          } else {
            viewModel.fetchData(widget.noSO,
                filterBy: _selectedFilter, idLokasi: _selectedLocation);
          }
        },
      ),
    );
  }

  Widget _buildCountText() {
    // Asumsi count didapatkan dari jumlah item yang ada di blokList
    final count = Provider.of<StockOpnameInputViewModel>(context).totalData;

    return Text(
      '$count Label', // Menampilkan jumlah item
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  void _showScanBarQRCode(BuildContext context) {
    if (_selectedLocation == null || _selectedLocation == 'Semua') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih lokasi terlebih dahulu.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeQrScanScreen(
          noSO: widget.noSO,
          selectedFilter: _selectedFilter ?? 'all',
          idLokasi: _selectedLocation!,
        ),
      ),
    );
  }

  void _showAddManualDialog(BuildContext context) {
    // if (_selectedLocation == null || _selectedLocation == 'Semua') {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Harap pilih lokasi terlebih dahulu.')),
    //   );
    //   return;
    // }

    // showDialog(
    //   context: context,
    //   builder: (BuildContext context) {
    //     return AddManualDialog(
    //       noSO: widget.noSO,
    //       selectedFilter: _selectedFilter ?? 'all',
    //       idLokasi: _selectedLocation!,
    //     );
    //   },
    // );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fitur ini telah di nonaktifkan')),
    );
  }
}
