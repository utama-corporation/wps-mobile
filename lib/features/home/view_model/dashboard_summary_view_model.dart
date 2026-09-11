import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../../../core/models/pagination_meta_model.dart';
import '../../mapping/model/mapping_lokasi_model.dart';

/// Ringkasan ringan untuk kartu di Home dashboard.
///
/// Mengambil dua data terpisah, masing-masing dengan try/catch & pesan error
/// sendiri sehingga kegagalan satu modul tidak menghapus data modul lain:
///  - Mapping  : GET /api/mapping/lokasi-summary  -> okupansi lokasi (client-side)
///  - QC BJ    : GET /api/qc-spk-bj?page=1&pageSize=1 -> meta.total = jumlah SPK aktif
class DashboardSummaryViewModel extends ChangeNotifier {
  bool _isLoading = false;
  DateTime? _lastUpdated;

  // Mapping
  int _totalLokasi = 0;
  int _lokasiTerisi = 0;
  int _totalLabel = 0;
  String _mappingError = '';

  // QC Barang Jadi
  int? _activeSpkCount;
  String _qcError = '';

  bool get isLoading => _isLoading;
  DateTime? get lastUpdated => _lastUpdated;

  int get totalLokasi => _totalLokasi;
  int get lokasiTerisi => _lokasiTerisi;
  int get totalLabel => _totalLabel;
  int get lokasiKosong => (_totalLokasi - _lokasiTerisi).clamp(0, _totalLokasi);
  String get mappingError => _mappingError;

  int? get activeSpkCount => _activeSpkCount;
  String get qcError => _qcError;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<void> refresh({bool mapping = true, bool qc = true}) =>
      load(mapping: mapping, qc: qc);

  Future<void> load({bool mapping = true, bool qc = true}) async {
    _isLoading = true;
    notifyListeners();

    final token = await _getToken();
    if (token == null) {
      const msg = 'Token tidak ditemukan. Harap login ulang.';
      if (mapping) _mappingError = msg;
      if (qc) _qcError = msg;
      _isLoading = false;
      notifyListeners();
      return;
    }

    await Future.wait([
      if (mapping) _fetchMapping(token) else Future<void>.value(),
      if (qc) _fetchQc(token) else Future<void>.value(),
    ]);

    _lastUpdated = DateTime.now();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchMapping(String token) async {
    try {
      final res = await http.get(
        Uri.parse(ApiConstants.mappingLokasiSummary),
        headers: _headers(token),
      );

      if (res.statusCode == 200) {
        final body = json.decode(utf8.decode(res.bodyBytes));
        final List<dynamic> rows = (body is Map ? body['data'] : null) ?? [];
        final list = rows
            .map((e) => LokasiSummaryModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _totalLokasi = list.length;
        _lokasiTerisi = list.where((l) => l.jumlahLabel > 0).length;
        _totalLabel = list.fold<int>(0, (s, l) => s + l.jumlahLabel);
        _mappingError = '';
      } else if (res.statusCode == 401) {
        _mappingError = 'Sesi berakhir. Login ulang.';
      } else {
        _mappingError = 'Gagal memuat mapping (${res.statusCode})';
      }
    } catch (_) {
      _mappingError = 'Gagal memuat mapping';
    }
  }

  Future<void> _fetchQc(String token) async {
    try {
      final uri = Uri.parse(ApiConstants.qcSpkBj).replace(
        queryParameters: {'page': '1', 'pageSize': '1'},
      );
      final res = await http.get(uri, headers: _headers(token));

      if (res.statusCode == 200) {
        final body = json.decode(utf8.decode(res.bodyBytes));
        if (body is Map && body['success'] == true) {
          final meta = PaginationMeta.fromJson(
            (body['meta'] as Map<String, dynamic>?) ?? const {},
          );
          _activeSpkCount = meta.total;
          _qcError = '';
        } else {
          _qcError = 'Gagal memuat SPK';
        }
      } else if (res.statusCode == 401) {
        _qcError = 'Sesi berakhir. Login ulang.';
      } else {
        _qcError = 'Gagal memuat SPK (${res.statusCode})';
      }
    } catch (_) {
      _qcError = 'Gagal memuat SPK';
    }
  }
}
