// lib/features/proses_produksi/model/proses_produksi_data.dart

/// Satu baris riwayat produksi hasil `GET /api/produksi/{proses}/history`.
///
/// Bentuk data mengikuti WPS Tablet (tabel utama pada tiap aktivitas proses
/// produksi): NoProduksi, Tanggal, Shift, Mesin, Operator.
class ProsesProduksiData {
  final String noProduksi;
  final String tanggal;
  final String shift;
  final String namaMesin;
  final String jamKerja;
  final String jmlhAnggota;
  final String operatorName;
  final String jenisOutput;

  const ProsesProduksiData({
    required this.noProduksi,
    this.tanggal = '',
    this.shift = '',
    this.namaMesin = '-',
    this.jamKerja = '',
    this.jmlhAnggota = '',
    this.operatorName = '-',
    this.jenisOutput = '',
  });

  factory ProsesProduksiData.fromJson(Map<String, dynamic> json) {
    return ProsesProduksiData(
      noProduksi: _str(json['NoProduksi'], '-'),
      tanggal: _str(json['Tanggal']),
      shift: _str(json['Shift']),
      namaMesin: _str(json['NamaMesin'], '-'),
      jamKerja: _str(json['JamKerja']),
      jmlhAnggota: _str(json['JmlhAnggota']),
      operatorName: _str(json['OperatorName'], '-'),
      jenisOutput: _str(json['JenisOutput']),
    );
  }

  /// Sama seperti filter live di WPS Tablet: cocokkan NoProduksi, Shift,
  /// Tanggal, Mesin, atau Operator (case-insensitive).
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return noProduksi.toLowerCase().contains(q) ||
        shift.toLowerCase().contains(q) ||
        tanggal.toLowerCase().contains(q) ||
        namaMesin.toLowerCase().contains(q) ||
        operatorName.toLowerCase().contains(q);
  }

  static String _str(dynamic v, [String fallback = '-']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }
}
