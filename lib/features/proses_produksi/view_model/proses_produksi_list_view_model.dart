// lib/features/proses_produksi/view_model/proses_produksi_list_view_model.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../model/proses_produksi_data.dart';
import '../model/proses_produksi_process.dart';

/// Mengambil daftar riwayat produksi satu proses (`GET /history`) lalu
/// melakukan filter + pagination di sisi client, sama seperti WPS Tablet
/// yang menarik seluruh data lalu memfilter saat pengguna mengetik di kotak
/// search (dengan batas 50 baris per halaman).
class ProsesProduksiListViewModel extends ChangeNotifier {
  static const int pageChunk = 50;

  final ProsesProduksiProcess process;

  /// Data mentah dari server (belum difilter).
  final List<ProsesProduksiData> _all = [];

  /// Hasil filter pencarian + [query].
  final List<ProsesProduksiData> _filtered = [];

  bool _isLoading = false;
  String _error = '';
  String _query = '';
  int _visibleCount = pageChunk;

  ProsesProduksiListViewModel(this.process);

  // ================= GETTERS =================

  /// Baris yang sudah difilter, dipotong [_visibleCount].
  List<ProsesProduksiData> get items =>
      _filtered.take(_visibleCount).toList(growable: false);

  bool get isLoading => _isLoading;
  String get error => _error;
  String get query => _query;

  /// Jumlah baris setelah filter (bukan jumlah yang sedang tampil).
  int get totalFiltered => _filtered.length;

  /// Jumlah seluruh data yang ditarik dari server.
  int get totalAll => _all.length;

  bool get canLoadMore => _visibleCount < _filtered.length && !_isLoading;

  bool get isEmpty => !_isLoading && _filtered.isEmpty;

  // ================= ACTIONS =================

  Future<void> refresh() async {
    _isLoading = true;
    _error = '';
    _visibleCount = pageChunk;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Unauthorized: no token';
        return;
      }

      // Backend membalas data dalam bentuk terpaginasi:
      // { success, message, data: { items, page, pageSize, total, totalPages } }.
      // Beberapa versi lama membalas array polos atau { data: [...] }. Tarik
      // semua halaman agar filter pencarian (client-side) tetap mencakup
      // seluruh data, sama seperti perilaku lama.
      final list = <ProsesProduksiData>[];
      var page = 1;
      var total = 0;
      var hasMore = true;
      var paginated = false;

      while (hasMore) {
        final uri = Uri.parse(
          '${ApiConstants.prosesProduksiHistory(process.apiSegment)}'
          '?page=$page&pageSize=200',
        );

        final resp = await http.get(
          uri,
          headers: {'Authorization': 'Bearer $token'},
        );

        if (resp.statusCode == 401 || resp.statusCode == 403) {
          _error = resp.statusCode == 401
              ? 'Sesi Anda sudah berakhir. Silakan login kembali.'
              : 'Anda tidak punya akses untuk data ini.';
          return;
        }
        if (resp.statusCode != 200) {
          _error = _serverMessage(resp) ?? 'Server error (${resp.statusCode})';
          return;
        }

        final body = json.decode(utf8.decode(resp.bodyBytes));

        if (body is Map && body['success'] != null && body['success'] != true) {
          _error = body['message']?.toString() ?? 'Gagal memuat data';
          return;
        }

        final List<dynamic> raw;
        if (body is List) {
          raw = body;
        } else if (body is Map) {
          final data = body['data'];
          if (data is List) {
            raw = data;
          } else if (data is Map) {
            final items = data['items'] ??
                data['data'] ??
                data['rows'] ??
                data['results'];
            if (items is List) {
              raw = items;
            } else {
              _error = 'Gagal memuat data';
              return;
            }
            if (data['total'] is num || data['totalPages'] is num) {
              paginated = true;
              if (data['total'] is num) total = (data['total'] as num).toInt();
            }
          } else if (body['items'] is List) {
            raw = body['items'] as List;
            if (body['total'] is num) {
              paginated = true;
              total = (body['total'] as num).toInt();
            }
          } else {
            _error = 'Gagal memuat data';
            return;
          }
        } else {
          _error = 'Gagal memuat data';
          return;
        }

        for (final e in raw) {
          if (e is Map) {
            list.add(ProsesProduksiData.fromJson(e.cast<String, dynamic>()));
          }
        }

        if (!paginated) {
          hasMore = false;
        } else {
          page += 1;
          hasMore = total > list.length && raw.isNotEmpty;
        }
      }

      _all
        ..clear()
        ..addAll(list);
      _applyFilter();
      _error = '';
    } on FormatException catch (e) {
      _error =
          'Server mengembalikan data bukan JSON. Periksa koneksi/mode jaringan. '
          'Detail: ${e.message}';
    } catch (e) {
      _error = 'Koneksi/unknown error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filter live (dipanggil saat pengguna mengetik di search field).
  void setQuery(String q) {
    _query = q;
    _visibleCount = pageChunk;
    _applyFilter();
    notifyListeners();
  }

  void clearQuery() => setQuery('');

  /// Tambah 50 baris berikutnya (dipanggil saat scroll mendekati bawah).
  void loadMore() {
    if (!canLoadMore) return;
    _visibleCount += pageChunk;
    notifyListeners();
  }

  // ================= INTERNAL =================

  void _applyFilter() {
    _filtered
      ..clear()
      ..addAll(
          _query.trim().isEmpty ? _all : _all.where((e) => e.matches(_query)));
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  String? _serverMessage(http.Response resp) {
    if (resp.bodyBytes.isEmpty) return null;
    try {
      final decoded = json.decode(utf8.decode(resp.bodyBytes));
      if (decoded is Map && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {}
    return null;
  }
}
