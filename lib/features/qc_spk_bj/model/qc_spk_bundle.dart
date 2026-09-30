// lib/features/qc_spk_bj/model/qc_spk_bundle.dart
import '../../../constants/api_constants.dart';

class QcSpkBundle {
  /// Maksimal foto untuk bidang dimensi (tebal/lebar/panjang).
  static const int maxPhotosPerField = 3;

  /// Maksimal foto untuk bundle — cukup 1 foto keseluruhan bundle.
  static const int maxBundlePhotos = 1;

  /// Maksimal foto sesuai nama field (fotoTebal/fotoLebar/fotoPanjang/fotoBundle).
  static int maxPhotosForField(String field) =>
      field == 'fotoBundle' ? maxBundlePhotos : maxPhotosPerField;

  final int? noBundle;
  final double? tebal;
  final double? lebar;
  final double? panjang;
  final int? jumlahPcs;
  final List<String> fotoTebalUrls;
  final List<String> fotoLebarUrls;
  final List<String> fotoPanjangUrls;
  final List<String> fotoBundleUrls;
  final List<String> fotoTebalCaptions;
  final List<String> fotoLebarCaptions;
  final List<String> fotoPanjangCaptions;
  final List<String> fotoBundleCaptions;

  /// Nomor kolom DB tiap URL pada field yang sama (0 = kolom tanpa sufiks).
  /// Dipakai agar keterangan menempel pada kolom yang benar walaupun ada
  /// foto di tengah yang dihapus. Kosong = server tidak mengirimnya.
  final List<int> fotoTebalSlots;
  final List<int> fotoLebarSlots;
  final List<int> fotoPanjangSlots;
  final List<int> fotoBundleSlots;

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
    this.fotoTebalCaptions = const [],
    this.fotoLebarCaptions = const [],
    this.fotoPanjangCaptions = const [],
    this.fotoBundleCaptions = const [],
    this.fotoTebalSlots = const [],
    this.fotoLebarSlots = const [],
    this.fotoPanjangSlots = const [],
    this.fotoBundleSlots = const [],
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
    final list =
        _photoUrlList(j['${field}sUrl'], limit: maxPhotosForField(field));
    if (list.isNotEmpty) return list;
    final single = _photoUrl(j['${field}Url']);
    return single == null ? const [] : [single];
  }

  /// Nilai ukur per foto, sejajar urutannya dengan daftar URL bidang yang sama.
  static List<String> _captions(dynamic v) {
    if (v is! List) return const [];
    return v.map((e) => e?.toString() ?? '').toList();
  }

  /// Nomor kolom DB untuk setiap URL. Bila server tidak mengirimnya, pakai
  /// urutan tampilan (perilaku lama) supaya data sebelum upgrade tetap jalan.
  static List<int> _slots(dynamic v, int count, int max) {
    if (v is! List) return List.generate(count, (i) => i);
    final out = <int>[];
    for (var i = 0; i < count; i++) {
      final s = i < v.length ? _toI(v[i]) : null;
      out.add(s != null && s >= 0 && s < max ? s : i);
    }
    return out;
  }

  factory QcSpkBundle.fromJson(Map<String, dynamic> j) {
    final urls = <String, List<String>>{
      'fotoTebal': _photos(j, 'fotoTebal'),
      'fotoLebar': _photos(j, 'fotoLebar'),
      'fotoPanjang': _photos(j, 'fotoPanjang'),
      'fotoBundle': _photos(j, 'fotoBundle'),
    };
    List<int> slotsOf(String field) {
      final max = maxPhotosForField(field);
      return _slots(j['${field}Slots'], urls[field]!.length, max);
    }

    return QcSpkBundle(
      noBundle: _toI(j['noBundle']),
      tebal: _toD(j['tebal']),
      lebar: _toD(j['lebar']),
      panjang: _toD(j['panjang']),
      jumlahPcs: _toI(j['jumlahPcs']),
      fotoTebalUrls: urls['fotoTebal']!,
      fotoLebarUrls: urls['fotoLebar']!,
      fotoPanjangUrls: urls['fotoPanjang']!,
      fotoBundleUrls: urls['fotoBundle']!,
      fotoTebalCaptions: _captions(j['fotoTebalCaptions']),
      fotoLebarCaptions: _captions(j['fotoLebarCaptions']),
      fotoPanjangCaptions: _captions(j['fotoPanjangCaptions']),
      fotoBundleCaptions: _captions(j['fotoBundleCaptions']),
      fotoTebalSlots: slotsOf('fotoTebal'),
      fotoLebarSlots: slotsOf('fotoLebar'),
      fotoPanjangSlots: slotsOf('fotoPanjang'),
      fotoBundleSlots: slotsOf('fotoBundle'),
    );
  }

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
    List<String>? fotoTebalCaptions,
    List<String>? fotoLebarCaptions,
    List<String>? fotoPanjangCaptions,
    List<String>? fotoBundleCaptions,
    List<int>? fotoTebalSlots,
    List<int>? fotoLebarSlots,
    List<int>? fotoPanjangSlots,
    List<int>? fotoBundleSlots,
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
      fotoTebalCaptions: fotoTebalCaptions ?? this.fotoTebalCaptions,
      fotoLebarCaptions: fotoLebarCaptions ?? this.fotoLebarCaptions,
      fotoPanjangCaptions: fotoPanjangCaptions ?? this.fotoPanjangCaptions,
      fotoBundleCaptions: fotoBundleCaptions ?? this.fotoBundleCaptions,
      fotoTebalSlots: fotoTebalSlots ?? this.fotoTebalSlots,
      fotoLebarSlots: fotoLebarSlots ?? this.fotoLebarSlots,
      fotoPanjangSlots: fotoPanjangSlots ?? this.fotoPanjangSlots,
      fotoBundleSlots: fotoBundleSlots ?? this.fotoBundleSlots,
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
