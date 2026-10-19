import 'package:flutter/material.dart';
import 'nyangkut_list_screen.dart';
import 'barcode_qr_scan_lancar_screen.dart';
import '../view_model/barcode_qr_scan_lancar_view_model.dart';
import 'package:provider/provider.dart';

class NyangkutMenuScreen extends StatelessWidget {
  const NyangkutMenuScreen({super.key});

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 60, color: Color(0xFF2E6F5D)),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E6F5D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Mode', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E6F5D),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 30),
        children: [
          _buildModeCard(
            icon: Icons.list_alt_rounded,
            title: 'Mode Nyangkut',
            description: 'Lihat dan kelola daftar label yang nyangkut.',
            onTap: () {
              // Navigasi ke daftar nyangkut
              Navigator.push(context, MaterialPageRoute(builder: (_) => NyangkutListScreen()));
            },
          ),
          _buildModeCard(
            icon: Icons.qr_code_scanner,
            title: 'Mode Lancar',
            description: 'Pindai label QR untuk melancarkan statusnya.',
            onTap: () {
              // Navigasi ke scanner QR
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider(
                    create: (_) => BarcodeQrScanLancarViewModel(),
                    child: const BarcodeQrScanLancarScreen(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
