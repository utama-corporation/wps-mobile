import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get changePassword => '$baseUrl/api/change-password';
  static String get login => '$baseUrl/api/auth/login2';
  static String get checkLabel => '$baseUrl/api/label-list/check';
  static String get saveChanges => '$baseUrl/api/label-list/save-changes';

  // Mapping Lokasi (flow baru)
  static String get mappingLokasiSummary =>
      '$baseUrl/api/mapping/lokasi-summary';
  static String mappingLokasiLabels(String idLokasi) =>
      '$baseUrl/api/mapping/lokasi-labels?idlokasi=${Uri.encodeComponent(idLokasi)}';
  static String get listNoSO => '$baseUrl/api/no-stock-opname';
  static String get listNyangkut => '$baseUrl/api/nyangkut-list';
  static String get listNoKD => '$baseUrl/api/kd-bongkar';
  static String get mstLokasi => '$baseUrl/api/mst-lokasi';

  static String get checkKdBongkar => '$baseUrl/api/kd-bongkar/check';
  static String get updateKdBongkar => '$baseUrl/api/kd-bongkar/scan';

  static String scanLabel(String noSO) =>
      '$baseUrl/api/no-stock-opname/$noSO/scan';

  static String scanLabelNyangkut(String noNyangkut) =>
      '$baseUrl/api/label-nyangkut/$noNyangkut';

  static String scanLabelLancar(String noLabel) =>
      '$baseUrl/api/label-nyangkut/lancar/$noLabel';

  static String labelData(String noLabel) => '$baseUrl/api/label-data/$noLabel';

  static String labelSOList({
    required String selectedNoSO,
    required int page,
    required int pageSize,
    String? filterBy,
    String? idLokasi,
  }) {
    final filter = filterBy ?? 'all';
    final lokasi = idLokasi ?? 'all';
    return '$baseUrl/api/no-stock-opname/$selectedNoSO?page=$page&pageSize=$pageSize&filterBy=$filter&idlokasi=$lokasi';
  }

  static String labelSOListLoadMore({
    required String selectedNoSO,
    required int page,
    required int loadMoreSize,
    String? filterBy,
    String? idLokasi,
  }) {
    final filter = filterBy ?? 'all';
    final lokasi = idLokasi ?? 'all';
    return '$baseUrl/api/no-stock-opname/$selectedNoSO?page=$page&pageSize=$loadMoreSize&filterBy=$filter&idlokasi=$lokasi';
  }

  static String labelList({
    required int page,
    required int pageSize,
    String? filterBy,
    String? idLokasi,
  }) {
    final filter = filterBy ?? 'all';
    final lokasi = idLokasi ?? 'all';
    return '$baseUrl/api/label-list?page=$page&pageSize=$pageSize&filterBy=$filter&idlokasi=$lokasi';
  }

  static String labelListLoadMore({
    required int page,
    required int loadMoreSize,
    String? filterBy,
    String? idLokasi,
  }) {
    final currentFilter = filterBy ?? 'all';
    final currentLocation = idLokasi ?? 'all';
    return '$baseUrl/api/label-list?page=$page&pageSize=$loadMoreSize&filterBy=$currentFilter&idlokasi=$currentLocation';
  }

  static String labelNyangkut({
    required String nonyangkut,
    required int page,
    required int pageSize,
    String? filterBy,
    String? idLokasi,
  }) {
    final filter = filterBy ?? 'all';
    final lokasi = idLokasi ?? 'all';
    return '$baseUrl/api/label-nyangkut/$nonyangkut?page=$page&pageSize=$pageSize&filterBy=$filter&idlokasi=$lokasi';
  }
}
