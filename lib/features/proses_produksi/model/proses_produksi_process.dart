// lib/features/proses_produksi/model/proses_produksi_process.dart
import 'package:flutter/material.dart';

/// Definisi satu proses produksi.
///
/// [apiSegment] harus sama dengan folder router di wps_backend
/// (`src/app.js` -> `app.use("/api/produksi/<apiSegment>", ...)`).
/// [permission] memakai kode `label_*` yang sudah ada di backend.
class ProsesProduksiProcess {
  final String apiSegment;
  final String title;
  final String description;
  final IconData icon;

  /// Permission untuk membuka daftar proses ini.
  final String permission;

  const ProsesProduksiProcess({
    required this.apiSegment,
    required this.title,
    required this.description,
    required this.icon,
    required this.permission,
  });
}

const kProsesProduksiBrand = Color(0xFF2E6F5D);

const List<ProsesProduksiProcess> prosesProduksiProcesses = [
  ProsesProduksiProcess(
    apiSegment: 's4s',
    title: 'S4S',
    description: 'Produksi S4S (sided & surfaced)',
    icon: Icons.square_foot_outlined,
    permission: 'label_s4s:read',
  ),
  ProsesProduksiProcess(
    apiSegment: 'finger-join',
    title: 'Finger Joint',
    description: 'Produksi finger joint',
    icon: Icons.join_inner_outlined,
    permission: 'label_fj:read',
  ),
  ProsesProduksiProcess(
    apiSegment: 'moulding',
    title: 'Moulding',
    description: 'Produksi moulding',
    icon: Icons.view_column_outlined,
    permission: 'label_mld:read',
  ),
  ProsesProduksiProcess(
    apiSegment: 'laminating',
    title: 'Laminating',
    description: 'Produksi laminating',
    icon: Icons.layers_outlined,
    permission: 'label_lmt:read',
  ),
  ProsesProduksiProcess(
    apiSegment: 'ccakhir',
    title: 'Cross Cut',
    description: 'Produksi cross cut akhir',
    icon: Icons.content_cut_outlined,
    permission: 'label_cca:read',
  ),
  ProsesProduksiProcess(
    apiSegment: 'sanding',
    title: 'Sanding',
    description: 'Produksi sanding',
    icon: Icons.grain_outlined,
    permission: 'label_snd:read',
  ),
  ProsesProduksiProcess(
    apiSegment: 'packing',
    title: 'Barang Jadi',
    description: 'Produksi barang jadi (packing)',
    icon: Icons.inventory_2_outlined,
    permission: 'label_bj:read',
  ),
];

/// Semua permission yang relevan untuk menu Proses Produksi.
final List<String> prosesProduksiPermissions =
    prosesProduksiProcesses.map((p) => p.permission).toList();
