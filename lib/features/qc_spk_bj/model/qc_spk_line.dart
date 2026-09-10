// lib/features/qc_spk_bj/model/qc_spk_line.dart
class QcSpkLine {
  final int lineNo;
  final int idBarangJadi;
  final String? namaBarangJadi;
  final int idJenisKayu;
  final String? namaJenisKayu;
  final double? tebal;
  final double? lebar;
  final double? panjang;
  final int bundle; // target jumlah bundle dari MstSPK_d
  final int pcsPerBundle;
  final String? keterangan;
  final int qcCount; // jumlah bundle yang sudah di-QC
  final int qcPcsTotal; // akumulasi pcs hasil QC

  QcSpkLine({
    required this.lineNo,
    required this.idBarangJadi,
    this.namaBarangJadi,
    required this.idJenisKayu,
    this.namaJenisKayu,
    this.tebal,
    this.lebar,
    this.panjang,
    this.bundle = 0,
    this.pcsPerBundle = 0,
    this.keterangan,
    this.qcCount = 0,
    this.qcPcsTotal = 0,
  });

  static double? _toD(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static int? _toI(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory QcSpkLine.fromJson(Map<String, dynamic> j) => QcSpkLine(
        lineNo: _toI(j['lineNo']) ?? 0,
        idBarangJadi: _toI(j['idBarangJadi']) ?? 0,
        namaBarangJadi: j['namaBarangJadi']?.toString(),
        idJenisKayu: _toI(j['idJenisKayu']) ?? 0,
        namaJenisKayu: j['namaJenisKayu']?.toString(),
        tebal: _toD(j['tebal']),
        lebar: _toD(j['lebar']),
        panjang: _toD(j['panjang']),
        bundle: _toI(j['bundle']) ?? 0,
        pcsPerBundle: _toI(j['pcsPerBundle']) ?? 0,
        keterangan: j['keterangan']?.toString(),
        qcCount: _toI(j['qcCount']) ?? 0,
        qcPcsTotal: _toI(j['qcPcsTotal']) ?? 0,
      );

  String _fmt(double? n) {
    if (n == null) return '-';
    return n % 1 == 0 ? n.toStringAsFixed(0) : n.toString();
  }

  String get dimensiLabel => '${_fmt(tebal)} x ${_fmt(lebar)} x ${_fmt(panjang)}';

  String get progressLabel => '$qcCount/$bundle bundle';

  bool get isComplete => bundle > 0 && qcCount >= bundle;
}
