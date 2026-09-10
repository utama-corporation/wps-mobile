import 'dart:async'; // Import Timer
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../view_model/mapping_lokasi_view_model.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';


class BarcodeQrScanMappingScreen extends StatefulWidget {
  final String selectedFilter;
  final String idLokasi;

  const BarcodeQrScanMappingScreen({Key? key, required this.selectedFilter, required this.idLokasi}) : super(key: key);

  @override
  _BarcodeQrScanMappingScreenState createState() => _BarcodeQrScanMappingScreenState();
}

class _BarcodeQrScanMappingScreenState extends State<BarcodeQrScanMappingScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController();
  String? _scanResult;
  bool isFlashOn = false;
  bool hasCameraPermission = false;
  late AnimationController _animationController;
  bool _isDetected = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Set<String> scannedCodes = Set<String>();



  bool _isSaving = false; // State untuk loading
  String _saveMessage = ''; // State untuk pesan

  Timer? _debounceTimer; // Timer untuk debouncing
  String? _lastScannedCode; // Kode yang terakhir diproses

  @override
  void initState() {
    super.initState();
    _getCameraPermission();



    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
  }



  Future<void> _getCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      hasCameraPermission = status == PermissionStatus.granted;
    });

    if (status == PermissionStatus.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Izin kamera ditolak. Buka pengaturan aplikasi untuk memberikan izin.'),
          action: SnackBarAction(
            label: 'Buka Pengaturan',
            onPressed: () {
              openAppSettings();
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    _animationController.dispose();
    _debounceTimer?.cancel(); // Batalkan timer jika ada
    super.dispose();
  }

  void _processScanResult(String rawValue) async {
    // Selalu jalankan proses scan
    if (rawValue != _lastScannedCode) { // Hanya proses jika kode berbeda
      _lastScannedCode = rawValue; // Update kode terakhir

      final viewModel = Provider.of<MappingLokasiViewModel>(context, listen: false);
      viewModel.processScannedCode(
        rawValue,
        widget.idLokasi,
        onSaveComplete: (success, statusCode, message) {
          if (statusCode == 201 || statusCode == 200) {
            // Tambahkan hasil scan ke dalam list hanya jika belum ada
            if (!scannedCodes.contains(rawValue)) {
              scannedCodes.add(rawValue); // Menambahkan kode jika belum ada dalam list
            }

            // Memutar suara accepted.mp3 dengan kecepatan 2x
            _audioPlayer.setPlaybackRate(2.0); // Kecepatan 2x
            _audioPlayer.play(AssetSource('sounds/accepted.mp3'));
          } else {
            // Memutar suara denied.mp3 dengan kecepatan 2x
            _audioPlayer.setPlaybackRate(2.0); // Kecepatan 2x
            _audioPlayer.play(AssetSource('sounds/denied.mp3'));
            Vibration.vibrate(duration: 1000);
          }

          final viewModel = Provider.of<MappingLokasiViewModel>(
              context, listen: false);
          viewModel.fetchLokasiLabels(widget.idLokasi);

          setState(() {
            _isSaving = false;
            _saveMessage = message; // Gabungkan pesan dan hasil scan
          });

          // Hapus pesan setelah beberapa detik
          Future.delayed(const Duration(seconds: 3), () {
            setState(() {
              _saveMessage = '';
            });
            _lastScannedCode = null; // Reset setelah pesan hilang
          });
        },
      );
    } else {
      debugPrint('Duplicate scan detected, skipping.');
    }
  }


  void _updateScanResult() async {
    final viewModel = Provider.of<MappingLokasiViewModel>(context, listen: false);

    // Konversi Set ke List untuk diproses oleh server
    List<String> scannedCodesList = scannedCodes.toList();

    // Periksa jika ada kode yang dipindai
    if (scannedCodesList.isNotEmpty) {
      viewModel.updateScannedCode(
        scannedCodesList,  // Kirimkan seluruh list yang sudah dipindai
        widget.idLokasi,
        onSaveComplete: (success, statusCode, message) {
          // Fetch data terbaru setelah menyimpan
          viewModel.fetchLokasiLabels(widget.idLokasi);
        },
      );
    }
    else {
      debugPrint('Duplicate scan detected, skipping.');
    }
  }

  Future<bool> _popScannedCodesNotEmpty() async {
    // Periksa apakah scannedCodes kosong atau null
    if (scannedCodes.isEmpty) {
      // Jika kosong, langsung kembali ke halaman sebelumnya tanpa menampilkan dialog
      return true;
    }

    // Jika tidak kosong, tampilkan dialog konfirmasi
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Perubahan Belum Disimpan!'),
          content: const Text('Ada perubahan yang belum disimpan. Apakah Anda ingin menyimpannya sebelum keluar?'),
          actions: <Widget>[
            // Tombol "Batal" untuk menutup dialog tanpa melakukan apa-apa
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Tidak kembali
              child: const Text('Batal'),
            ),
            // Tombol "Tidak" untuk kembali tanpa memanggil fungsi update
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Tidak kembali
              child: const Text('Tidak'),
            ),
            // Tombol "Ya" untuk memanggil fungsi update dan kembali ke halaman sebelumnya
            TextButton(
              onPressed: () {
                // Panggil fungsi untuk memperbarui hasil scan
                _updateScanResult();

                // Clear scannedCodes setelah konfirmasi
                setState(() {
                  scannedCodes.clear(); // Kosongkan scannedCodes
                });

                // Kembali ke halaman sebelumnya setelah update dan clear
                Navigator.of(context).pop(true); // Kembali ke halaman sebelumnya

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Lokasi berhasil diperbaharui!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    // Mengembalikan nilai apakah user ingin kembali
    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final scanAreaSize = screenWidth * 0.6;
    final count = Provider.of<MappingLokasiViewModel>(context).totalLabelData;

    return WillPopScope(
        onWillPop: _popScannedCodesNotEmpty, // Memanggil fungsi konfirmasi keluar
    child:  Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          '${widget.idLokasi} | ${count} Label',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white, // Set background color to white
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black), // Set icon color to black
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_off : Icons.flash_on,
              color: Colors.black, // Set the icon color to black
            ),
            onPressed: () async {
              setState(() {
                isFlashOn = !isFlashOn;
              });

              // Toggle torch (flashlight)
              cameraController.toggleTorch();
            },
          ),
          // Tombol untuk menampilkan dialog dengan list scannedCodes
          IconButton(
            icon: Icon(Icons.list, color: Colors.black),
            onPressed: () {
              // Tampilkan dialog dengan data scannedCodes
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Hasil Scan ( ${scannedCodes.length} )'),
                    content: SizedBox(
                      width: double.minPositive,
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: scannedCodes.length,
                        itemBuilder: (context, index) {
                          final item = scannedCodes.toList()[index];
                          return Dismissible(
                            key: Key(item), // Key unik untuk animasi
                            direction: DismissDirection.endToStart, // Geser ke kiri untuk hapus
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: EdgeInsets.only(right: 20),
                              child: Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              setState(() {
                                scannedCodes.remove(item);
                              });

                              // ScaffoldMessenger.of(context).showSnackBar(
                              //   SnackBar(content: Text('"$item" dihapus ${scannedCodes.length}')),
                              // );
                            },
                            child: Column(
                              children: [
                                ListTile(
                                  title: Text(item),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                ),
                                Divider(height: 1),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          _updateScanResult();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text('Lokasi berhasil diperbaharui!'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text('Simpan'),
                      ),
                    ],
                  );
                },
              );

            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (hasCameraPermission)
            MobileScanner(
              controller: cameraController,
              scanWindow: Rect.fromCenter(
                center: Offset(screenWidth / 2, screenHeight / 2),
                width: scanAreaSize,
                height: scanAreaSize,
              ),
              onDetect: (capture) {
                try {
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty && barcodes.first != null) {
                    final String? rawValue = barcodes.first.rawValue; // Simpan rawValue di variabel lokal
                    if (rawValue != null && !_isDetected) { // Pastikan rawValue tidak null
                      setState(() {
                        _scanResult = rawValue;
                        _isDetected = true;
                      });
                      _animationController.forward(from: 0);

                      if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
                      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                        setState(() {
                          _isDetected = false;
                        });
                        _processScanResult(rawValue); // Panggil fungsi pemrosesan
                      });
                    }
                  }
                  else {
                    setState(() {
                      _scanResult = null;
                      _isDetected = false;
                    });
                  }
                } catch (e) {
                  debugPrint('Error during barcode detection: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Terjadi kesalahan saat memproses barcode.')),
                  );
                }
              },
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Izin kamera diperlukan untuk memindai.'),
                  ElevatedButton(
                    onPressed: () {
                      _getCameraPermission();
                    },
                    child: const Text('Minta Izin Kamera'),
                  ),
                ],
              ),
            ),

          // Tampilan Status
          Positioned(
            bottom: 50, // Atur jarak dari bawah
            left: 0,
            right: 0,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _isSaving
                  ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
                  : _saveMessage.isNotEmpty
                  ? Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.symmetric(horizontal: 20), // Tambahkan margin horizontal
                decoration: BoxDecoration(
                  color: _saveMessage.startsWith('Data berhasil') ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _saveMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ),

          // Ikon Status (check.png atau cross.png)
          if (_saveMessage.isNotEmpty) // Hanya tampilkan ikon jika ada pesan
            Positioned(
              top: 150, // Atur jarak dari bawah (sesuaikan dengan kebutuhan)
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _saveMessage.startsWith('Data berhasil')
                      ? Image.asset(
                    'assets/images/check.png', // Path ke check.png
                    key: const ValueKey('check'),
                    width: 120, // Sesuaikan ukuran ikon
                    height: 120,
                  )
                      : Image.asset(
                    'assets/images/cross.png', // Path ke cross.png
                    key: const ValueKey('cross'),
                    width: 80, // Sesuaikan ukuran ikon
                    height: 80,
                  ),
                ),
              ),
            ),

          // Box Decoration (tidak diubah)
          Align(
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isDetected ? Colors.greenAccent.withOpacity(0.8) : Colors.white.withOpacity(0.2),
                  width: 3,
                ),
              ),
            ),
          ),
        ],
       ),
      ),
    );

  }
}