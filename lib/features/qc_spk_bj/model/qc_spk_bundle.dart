// lib/features/qc_spk_bj/model/qc_spk_bundle.dart
import '../../../constants/api_constants.dart';

class QcSpkBundle {
  final int? noBundle;
  final double? tebal;
  final double? lebar;
  final double? panjang;
  final int? jumlahPcs;
  final String? fotoTebalUrl;
  final String? fotoLebarUrl;
  final String? fotoPanjangUrl;
  final String? fotoBundleUrl;

  QcSpkBundle({
    this.noBundle,
    this.tebal,
    this.lebar,
    this.panjang,
    this.jumlahPcs,
    this.fotoTebalUrl,
    this.fotoLebarUrl,
    this.fotoPanjangUrl,
    this.fotoBundleUrl,
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

  static String? _s(dynamic v) {
    final s = v?.toString();
    return (s == null || s.isEmpty) ? null : s;
  }

  /// URL foto: jadikan absolut (server kirim path relatif "/storage/...").
  static String? _photoUrl(dynamic v) {
    final s = _s(v);
    if (s == null) return null;
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final base = ApiConstants.baseUrl;
    return s.startsWith('/') ? '$base$s' : '$base/$s';
  }

  factory QcSpkBundle.fromJson(Map<String, dynamic> j) => QcSpkBundle(
        noBundle: _toI(j['noBundle']),
        tebal: _toD(j['tebal']),
        lebar: _toD(j['lebar']),
        panjang: _toD(j['panjang']),
        jumlahPcs: _toI(j['jumlahPcs']),
        fotoTebalUrl: _photoUrl(j['fotoTebalUrl']),
        fotoLebarUrl: _photoUrl(j['fotoLebarUrl']),
        fotoPanjangUrl: _photoUrl(j['fotoPanjangUrl']),
        fotoBundleUrl: _photoUrl(j['fotoBundleUrl']),
      );

  QcSpkBundle copyWith({
    int? noBundle,
    double? tebal,
    double? lebar,
    double? panjang,
    int? jumlahPcs,
    String? fotoTebalUrl,
    String? fotoLebarUrl,
    String? fotoPanjangUrl,
    String? fotoBundleUrl,
  }) {
    return QcSpkBundle(
      noBundle: noBundle ?? this.noBundle,
      tebal: tebal ?? this.tebal,
      lebar: lebar ?? this.lebar,
      panjang: panjang ?? this.panjang,
      jumlahPcs: jumlahPcs ?? this.jumlahPcs,
      fotoTebalUrl: fotoTebalUrl ?? this.fotoTebalUrl,
      fotoLebarUrl: fotoLebarUrl ?? this.fotoLebarUrl,
      fotoPanjangUrl: fotoPanjangUrl ?? this.fotoPanjangUrl,
      fotoBundleUrl: fotoBundleUrl ?? this.fotoBundleUrl,
    );
  }

  bool get hasAnyPhoto =>
      fotoTebalUrl != null ||
      fotoLebarUrl != null ||
      fotoPanjangUrl != null ||
      fotoBundleUrl != null;

  Map<String, dynamic> toPostMap() => {
        'noBundle': noBundle,
        if (tebal != null) 'tebal': tebal,
        if (lebar != null) 'lebar': lebar,
        if (panjang != null) 'panjang': panjang,
        if (jumlahPcs != null) 'jumlahPcs': jumlahPcs,
      };

  @override
  bool operator ==(Object other) =>
      other is QcSpkBundle &&
      other.noBundle == noBundle &&
      other.tebal == tebal &&
      other.lebar == lebar &&
      other.panjang == panjang &&
      other.jumlahPcs == jumlahPcs;

  @override
  int get hashCode => Object.hash(noBundle, tebal, lebar, panjang, jumlahPcs);
}
