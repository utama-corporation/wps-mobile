// lib/features/qc_spk_bj/model/qc_spk_header.dart

/// Ringkasan 1 baris detail SPK (untuk ditampilkan di kartu header).
class QcSpkHeaderLine {
  final String? namaBarangJadi;
  final String? namaJenisKayu;
  final double? tebal;
  final double? lebar;
  final double? panjang;
  final int bundle;
  final int pcsPerBundle;

  QcSpkHeaderLine({
    this.namaBarangJadi,
    this.namaJenisKayu,
    this.tebal,
    this.lebar,
    this.panjang,
    this.bundle = 0,
    this.pcsPerBundle = 0,
  });

  static double? _toD(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int _toI(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  factory QcSpkHeaderLine.fromJson(Map<String, dynamic> j) => QcSpkHeaderLine(
        namaBarangJadi: j['namaBarangJadi']?.toString(),
        namaJenisKayu: j['namaJenisKayu']?.toString(),
        tebal: _toD(j['tebal']),
        lebar: _toD(j['lebar']),
        panjang: _toD(j['panjang']),
        bundle: _toI(j['bundle']),
        pcsPerBundle: _toI(j['pcsPerBundle']),
      );

  String _fmt(double? n) {
    if (n == null) return '-';
    return n % 1 == 0 ? n.toStringAsFixed(0) : n.toString();
  }

  String get judul => namaBarangJadi ?? 'Barang Jadi';

  /// mis. "Merbau · 44 x 1100 x 4500 · 12 bundle"
  String get ringkas {
    final parts = <String>[];
    if ((namaJenisKayu ?? '').isNotEmpty) parts.add(namaJenisKayu!);
    parts.add('${_fmt(tebal)} x ${_fmt(lebar)} x ${_fmt(panjang)}');
    parts.add('$bundle bundle');
    return parts.join(' · ');
  }

  /// bentuk pendek untuk daftar produk, mis. "fjlb 20x20"
  String get pendek => '$judul ${_fmt(tebal)}x${_fmt(lebar)}'.trim();
}

class QcSpkHeader {
  final String noSPK;
  final String tanggal; // "YYYY-MM-DD"
  final String? noContract;
  final int? idBuyer;
  final String? namaBuyer;
  final String? tujuan;
  final int? shipmentPlan;
  final int totalLine;
  final List<QcSpkHeaderLine> lines;

  QcSpkHeader({
    required this.noSPK,
    required this.tanggal,
    this.noContract,
    this.idBuyer,
    this.namaBuyer,
    this.tujuan,
    this.shipmentPlan,
    this.totalLine = 0,
    this.lines = const [],
  });

  static int? _toI(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory QcSpkHeader.fromJson(Map<String, dynamic> j) {
    final rawLines = j['lines'] as List? ?? const [];
    return QcSpkHeader(
      noSPK: j['noSPK']?.toString() ?? '',
      tanggal: j['tanggal']?.toString() ?? '',
      noContract: j['noContract']?.toString(),
      idBuyer: _toI(j['idBuyer']),
      namaBuyer: j['namaBuyer']?.toString(),
      tujuan: j['tujuan']?.toString(),
      shipmentPlan: _toI(j['shipmentPlan']),
      totalLine: _toI(j['totalLine']) ?? 0,
      lines: rawLines
          .whereType<Map>()
          .map((e) => QcSpkHeaderLine.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
