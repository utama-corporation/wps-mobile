// Model untuk flow Mapping Lokasi baru:
//  1. GET /api/mapping/lokasi-summary   -> LokasiSummaryModel
//  2. GET /api/mapping/lokasi-labels    -> LokasiLabelModel + LokasiLabelDetailModel

class LokasiSummaryModel {
  final String idLokasi;
  final String blok;
  final String? description;
  final int jumlahLabel;

  LokasiSummaryModel({
    required this.idLokasi,
    required this.blok,
    this.description,
    required this.jumlahLabel,
  });

  factory LokasiSummaryModel.fromJson(Map<String, dynamic> json) {
    return LokasiSummaryModel(
      idLokasi: json['IdLokasi']?.toString() ?? '-',
      blok: json['Blok']?.toString() ?? '-',
      description: json['Description']?.toString(),
      jumlahLabel:
          int.tryParse(json['JumlahLabel']?.toString() ?? '0') ?? 0,
    );
  }
}

class LokasiLabelModel {
  final String labelNo;
  final String labelType;
  final String? jenis;
  final String? singkatan;
  final String? dateCreate;
  final int jumlah;

  /// "TON" untuk label ST (Sawn Timber), "M3" untuk kategori lain.
  final String volumeType;

  /// Total volume label dalam satuannya masing-masing (4 desimal, dari backend).
  final String ton;
  final String m3;
  final String volume;

  final List<LokasiLabelDetailModel> details;

  LokasiLabelModel({
    required this.labelNo,
    required this.labelType,
    this.jenis,
    this.singkatan,
    this.dateCreate,
    required this.jumlah,
    this.volumeType = 'M3',
    this.ton = '0.0000',
    this.m3 = '0.0000',
    this.volume = '0.0000',
    required this.details,
  });

  bool get hasDetails => details.isNotEmpty;
  int get totalDetails => details.length;
  bool get isTon => volumeType == 'TON';

  factory LokasiLabelModel.fromJson(Map<String, dynamic> json) {
    final rawDetails = (json['Details'] as List<dynamic>?) ?? [];
    return LokasiLabelModel(
      labelNo: json['LabelNo']?.toString() ?? '-',
      labelType: json['LabelType']?.toString() ?? '-',
      jenis: json['Jenis']?.toString(),
      singkatan: json['Singkatan']?.toString(),
      dateCreate: json['DateCreate']?.toString(),
      jumlah: int.tryParse(json['Jumlah']?.toString() ?? '0') ?? 0,
      volumeType: json['VolumeType']?.toString() ?? 'M3',
      ton: json['Ton']?.toString() ?? '0.0000',
      m3: json['M3']?.toString() ?? '0.0000',
      volume: json['Volume']?.toString() ?? '0.0000',
      details: rawDetails
          .map((e) =>
              LokasiLabelDetailModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LokasiLabelDetailModel {
  final int? noUrut;
  final double? tebal;
  final double? lebar;
  final double? panjang;
  final int? jmlhBatang;

  LokasiLabelDetailModel({
    this.noUrut,
    this.tebal,
    this.lebar,
    this.panjang,
    this.jmlhBatang,
  });

  factory LokasiLabelDetailModel.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) =>
        v == null ? null : double.tryParse(v.toString());
    int? toInt(dynamic v) => v == null ? null : int.tryParse(v.toString());

    return LokasiLabelDetailModel(
      noUrut: toInt(json['NoUrut']),
      tebal: toDouble(json['Tebal']),
      lebar: toDouble(json['Lebar']),
      panjang: toDouble(json['Panjang']),
      jmlhBatang: toInt(json['JmlhBatang']),
    );
  }
}
