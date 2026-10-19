import 'package:flutter/material.dart';
import 'kd_bongkar_out_screen.dart';
import 'kd_bongkar_in_screen.dart';

class KdBongkarSelectedScreen extends StatelessWidget {
  const KdBongkarSelectedScreen({super.key});

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
              Icon(icon, size: 60, color: const Color(0xFF2E6F5D)),
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
        title: const Text('Bongkar KD', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF2E6F5D),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 30),
        children: [
          _buildModeCard(
            icon: Icons.login,
            title: 'KD IN',
            description: 'Lihat daftar nomor KD yang belum keluar.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => KdBongkarInScreen()),
              );
            },
          ),
          _buildModeCard(
            icon: Icons.logout,
            title: 'KD OUT',
            description: 'Lihat daftar nomor KD yang sudah keluar.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => KdBongkarOutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
