// lib/features/qc_spk_bj/model/qc_spk_bundle.dart
import '../../../constants/api_constants.dart';

class QcSpkBundle {
  /// Maksimal foto per bidang (tebal/lebar/panjang/bundle).
  static const int maxPhotosPerField = 3;

  final int? noBundle;
  final double? tebal;
  final double? lebar;
  final double? panjang;
  final int? jumlahPcs;
  final List<String> fotoTebalUrls;
  final List<String> fotoLebarUrls;
  final List<String> fotoPanjangUrls;
  final List<String> fotoBundleUrls;

  QcSpkBundle({
    this.noBundle,
    this.tebal,
    this.lebar,
    this.panjang,
    this.jumlahPcs,
    this.fotoTebalUrls = const [],
    this.fotoLebarUrls = const [],
    this.fotoPanjangUrls = const [],
    this.fotoBundleUrls = const [],
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

  /// Daftar URL absolut dari array, dibatasi [limit] elemen.
  static List<String> _photoUrlList(dynamic v,
      {int limit = maxPhotosPerField}) {
    if (v is! List) return const [];
    final out = <String>[];
    for (final e in v) {
      if (out.length >= limit) break;
      final u = _photoUrl(e);
      if (u != null) out.add(u);
    }
    return out;
  }

  /// Baca foto sebuah bidang: utamakan array (`fotoTebalUrls`), fallback ke
  /// scalar lama (`fotoTebalUrl`) agar data sebelum upgrade tetap tampil.
  static List<String> _photos(Map<String, dynamic> j, String field) {
    final list = _photoUrlList(j['${field}sUrl']);
    if (list.isNotEmpty) return list;
    final single = _photoUrl(j['${field}Url']);
    return single == null ? const [] : [single];
  }

  factory QcSpkBundle.fromJson(Map<String, dynamic> j) => QcSpkBundle(
        noBundle: _toI(j['noBundle']),
        tebal: _toD(j['tebal']),
        lebar: _toD(j['lebar']),
        panjang: _toD(j['panjang']),
        jumlahPcs: _toI(j['jumlahPcs']),
        fotoTebalUrls: _photos(j, 'fotoTebal'),
        fotoLebarUrls: _photos(j, 'fotoLebar'),
        fotoPanjangUrls: _photos(j, 'fotoPanjang'),
        fotoBundleUrls: _photos(j, 'fotoBundle'),
      );

  QcSpkBundle copyWith({
    int? noBundle,
    double? tebal,
    double? lebar,
    double? panjang,
    int? jumlahPcs,
    List<String>? fotoTebalUrls,
    List<String>? fotoLebarUrls,
    List<String>? fotoPanjangUrls,
    List<String>? fotoBundleUrls,
  }) {
    return QcSpkBundle(
      noBundle: noBundle ?? this.noBundle,
      tebal: tebal ?? this.tebal,
      lebar: lebar ?? this.lebar,
      panjang: panjang ?? this.panjang,
      jumlahPcs: jumlahPcs ?? this.jumlahPcs,
      fotoTebalUrls: fotoTebalUrls ?? this.fotoTebalUrls,
      fotoLebarUrls: fotoLebarUrls ?? this.fotoLebarUrls,
      fotoPanjangUrls: fotoPanjangUrls ?? this.fotoPanjangUrls,
      fotoBundleUrls: fotoBundleUrls ?? this.fotoBundleUrls,
    );
  }

  List<List<String>> get allPhotoUrls => [
        fotoTebalUrls,
        fotoLebarUrls,
        fotoPanjangUrls,
        fotoBundleUrls,
      ];

  bool get hasAnyPhoto => allPhotoUrls.any((e) => e.isNotEmpty);

  /// Total foto tersimpan pada semua bidang.
  int get photoCount => allPhotoUrls.fold(0, (sum, e) => sum + e.length);

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
