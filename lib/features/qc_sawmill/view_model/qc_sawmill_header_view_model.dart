// lib/features/qc_sawmill/view_model/qc_sawmill_header_view_model.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../../../core/models/paginated_response_model.dart';
import '../model/qc_sawmill_header.dart';
import '../../../core/models/pagination_meta_model.dart';


class QcSawmillHeaderViewModel extends ChangeNotifier {
  // data
  final List<QcSawmillHeader> _items = [];
  PaginationMeta? _meta; // <-- pakai PaginationMeta generik

  // state
  bool _isLoading = false;
  String _error = '';

  // filters
  String _q = '';
  String _dateFrom = ''; // YYYY-MM-DD
  String _dateTo   = ''; // YYYY-MM-DD
  int? _idJenisKayu;

  // getters
  List<QcSawmillHeader> get items => List.unmodifiable(_items);
  PaginationMeta? get meta => _meta;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get canLoadMore => (_meta?.hasNext ?? false) && !_isLoading;

  // token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // === FILTER HELPERS ===
  void setSearch(String q) => _q = q.trim();
  void setDateRange({String? from, String? to}) {
    _dateFrom = (from ?? '').trim();
    _dateTo   = (to ?? '').trim();
  }
  void setJenisKayu(int? id) => _idJenisKayu = id;

  // === PAGINATION API ===
  Future<void> refreshFirstPage({int pageSize = 20}) async {
    _items.clear();
    _meta = null;
    _error = '';
    // penting: JANGAN notify di sini agar aman dari "notify during build"
    await _fetch(page: 1, pageSize: pageSize, append: false);
  }

  Future<void> loadNextPage() async {
    if (!canLoadMore) return;
    final nextPage = (_meta?.page ?? 1) + 1;
    await _fetch(page: nextPage, pageSize: _meta?.pageSize ?? 20, append: true);
  }

  Future<void> loadPage(int page, {int? pageSize}) async {
    final size = pageSize ?? (_meta?.pageSize ?? 20);
    await _fetch(page: page, pageSize: size, append: false);
  }

  // === CORE FETCH ===
  Future<void> _fetch({
    required int page,
    required int pageSize,
    required bool append,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Unauthorized: no token';
        return;
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}/api/qc-sawmill').replace(
        queryParameters: {
          'page'     : page.toString(),
          'pageSize' : pageSize.toString(),
          if (_q.isNotEmpty) 'q'         : _q,
          if (_dateFrom.isNotEmpty) 'dateFrom': _dateFrom,
          if (_dateTo.isNotEmpty)   'dateTo'  : _dateTo,
          if (_idJenisKayu != null) 'idJenisKayu': _idJenisKayu.toString(),
        },
      );

      final resp = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(resp.body);

        if (body['success'] != true) {
          _error = body['message']?.toString() ?? 'Gagal memuat data';
          return;
        }

        // ==== PARSING (dua opsi) ====

        // Opsi A: langsung manual
        // _meta = PaginationMeta.fromJson(body['meta'] ?? {});
        // final List<dynamic> arr = body['data'] ?? [];
        // final parsed = arr.map((e) => QcSawmillHeader.fromJson(e as Map<String, dynamic>)).toList();

        // Opsi B (REKOMENDASI): pakai PaginatedResponse<T> generik
        final parsed = PaginatedResponse<QcSawmillHeader>.fromJson(
          body,
              (m) => QcSawmillHeader.fromJson(m),
        );
        _meta = parsed.meta;
        final list = parsed.data;

        if (append) {
          _items.addAll(list);
        } else {
          _items
            ..clear()
            ..addAll(list);
        }
        _error = '';

      } else if (resp.statusCode == 401) {
        _error = 'Unauthorized: Token invalid/expired';
      } else {
        String? serverMessage;
        final raw = resp.body.trim();
        if (raw.isNotEmpty) {
          try {
            final decoded = json.decode(raw);
            if (decoded is Map<String, dynamic>) {
              serverMessage = decoded['message']?.toString();
            }
          } catch (_) {}
        }
        _error = serverMessage ?? 'Server error (${resp.statusCode})';
      }
    } on TypeError catch (e) {
      _error = 'Parsing error: $e';
    } on FormatException catch (e) {
      _error =
          'Server mengembalikan data bukan JSON (mungkin halaman HTML/404). '
          'Periksa koneksi/mode jaringan. Detail: ${e.message}';
    } catch (e) {
      _error = 'Koneksi/unknown error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  /// Hapus satu NoQC di server.
  /// Return true kalau sukses. vm.error diisi jika gagal.
  /// Setelah sukses: otomatis refresh halaman aktif (agar meta/total konsisten).
  Future<bool> deleteByNoQc(String noQc) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Unauthorized: no token';
        notifyListeners();
        return false;
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/qc-sawmill/${Uri.encodeComponent(noQc)}',
      );

      // (opsional) tunjukkan loading kecil global
      _isLoading = true;
      notifyListeners();

      final resp = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      final okStatus = resp.statusCode == 200 || resp.statusCode == 204;
      if (!okStatus) {
        // coba ambil message dari body
        final Map<String, dynamic>? body =
        resp.bodyBytes.isNotEmpty ? jsonDecode(utf8.decode(resp.bodyBytes)) : null;
        _error = body?['message']?.toString() ?? 'Server error (${resp.statusCode})';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // jika 204, tidak ada body
      if (resp.statusCode == 200) {
        final body = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        if (body['success'] != true) {
          _error = body['message']?.toString() ?? 'Gagal menghapus data';
          _isLoading = false;
          notifyListeners();
          return false;
        }
        // (opsional) kamu bisa baca meta delete:
        // final deletedDetails = (body['meta']?['deletedDetails'] ?? 0).toString();
        // final deletedHeader  = (body['meta']?['deletedHeader']  ?? 0).toString();
      }

      // Refresh halaman aktif agar meta.total, paging, dll sinkron
      final currentPage = _meta?.page ?? 1;
      await loadPage(currentPage);

      _error = '';
      return true;
    } catch (e) {
      _error = 'Koneksi/unknown error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // === UPDATE (EDIT) ===
  /// Update header by NoQC. Field opsional: [tgl] (YYYY-MM-DD), [idJenisKayu] (int), [meja] (String <= 50)
  /// Return true jika sukses. vm.error diisi jika gagal.
  Future<bool> updateHeaderByNoQc({
    required String noQc,
    String? tgl,
    int? idJenisKayu,
    String? meja,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Unauthorized: no token';
        notifyListeners();
        return false;
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/qc-sawmill/${Uri.encodeComponent(noQc)}',
      );

      // Kirim hanya field yang diisi
      final body = <String, dynamic>{};
      if (tgl != null && tgl.trim().isNotEmpty) body['tgl'] = tgl.trim();
      if (idJenisKayu != null) body['idJenisKayu'] = idJenisKayu;
      if (meja != null && meja.trim().isNotEmpty) body['meja'] = meja.trim();

      if (body.isEmpty) {
        _error = 'Tidak ada field untuk diupdate';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      notifyListeners();

      final resp = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (resp.statusCode == 200) {
        final map = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
        if (map['success'] != true) {
          _error = map['message']?.toString() ?? 'Gagal update';
          return false;
        }

        // Sinkronkan item di list (optimistic)
        final updated = map['data'] as Map?;
        if (updated != null) {
          final idx = _items.indexWhere((e) => e.noQc == noQc);
          if (idx >= 0) {
            _items[idx] = QcSawmillHeader(
              noQc: _items[idx].noQc,
              tgl: (updated['tgl'] ?? _items[idx].tgl).toString(),
              idJenisKayu: (updated['idJenisKayu'] is num)
                  ? (updated['idJenisKayu'] as num).toInt()
                  : int.tryParse('${updated['idJenisKayu']}'),
              // Catatan: API update header tidak mengembalikan 'namaJenisKayu'
              // jadi kita pertahankan nilai lama agar UI tetap tampil.
              namaJenisKayu: _items[idx].namaJenisKayu,
              meja: (updated['meja'] is num)
                  ? (updated['meja'] as num).toInt()
                  : int.tryParse('${updated['meja']}') ?? _items[idx].meja,
            );
          }
        }

        // Refresh page agar meta (totalPages/hasNext) konsisten
        await loadPage(_meta?.page ?? 1);

        _error = '';
        return true;
      } else {
        final Map<String, dynamic>? map =
        resp.bodyBytes.isNotEmpty ? jsonDecode(utf8.decode(resp.bodyBytes)) : null;
        _error = map?['message']?.toString() ?? 'Server error (${resp.statusCode})';
        return false;
      }
    } catch (e) {
      _error = 'Koneksi/unknown error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> createHeader({
    required String tgl,        // YYYY-MM-DD
    required int idJenisKayu,   // int
    String? meja,               // optional, <= 50 chars
  }) async {
    // helper untuk log ringkas
    String ellipsis(String? s, [int max = 500]) {
      if (s == null) return '<null>';
      if (s.length <= max) return s;
      return '${s.substring(0, max)}... (+${s.length - max} chars)';
    }

    final sw = Stopwatch()..start();
    Uri? uri;

    try {
      final token = await _getToken();
      if (token == null) {
        _error = 'Unauthorized: no token';
        print('[QC-CREATE] no token');
        notifyListeners();
        return false;
      }

      uri = Uri.parse('${ApiConstants.baseUrl}/api/qc-sawmill');

      final body = <String, dynamic>{
        'tgl': tgl.trim(),
        'idJenisKayu': idJenisKayu,
        if (meja != null && meja.trim().isNotEmpty) 'meja': meja.trim(),
      };

      // Validasi minimal di sisi client juga
      if (body['tgl'] == null || (body['tgl'] as String).isEmpty) {
        _error = 'tgl wajib diisi';
        print('[QC-CREATE] skip: tgl kosong');
        notifyListeners();
        return false;
      }
      if (body['idJenisKayu'] is! int) {
        _error = 'idJenisKayu harus integer';
        print('[QC-CREATE] skip: idJenisKayu bukan int');
        notifyListeners();
        return false;
      }

      _isLoading = true;
      notifyListeners();

      print('[QC-CREATE] POST $uri');
      print('[QC-CREATE] body: ${jsonEncode(body)}');

      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      final respText = utf8.decode(resp.bodyBytes);
      print('[QC-CREATE] status=${resp.statusCode} elapsed=${sw.elapsedMilliseconds}ms');
      print('[QC-CREATE] response: ${ellipsis(respText)}');

      if (resp.statusCode == 201) {
        final map = jsonDecode(respText) as Map<String, dynamic>;
        if (map['success'] != true) {
          _error = map['message']?.toString() ?? 'Gagal membuat data';
          return false;
        }

        // Server mengembalikan header baru (biasanya berisi NoQc yang auto)
        final data = (map['data'] as Map).cast<String, dynamic>();

        // Buat model lokal
        final created = QcSawmillHeader(
          noQc: data['noQc']?.toString() ?? '-',        // tergantung data balikan service
          tgl: data['tgl']?.toString() ?? tgl,
          idJenisKayu: (data['idJenisKayu'] is num)
              ? (data['idJenisKayu'] as num).toInt()
              : int.tryParse('${data['idJenisKayu']}') ?? idJenisKayu,
          // namaJenisKayu tidak dikembalikan di create—biarkan null/old
          namaJenisKayu: null,
          // meja bisa numeric/string; model kamu int?, jadi coba parse ke int
          meja: (data['meja'] is num)
              ? (data['meja'] as num).toInt()
              : int.tryParse('${data['meja']}'),
        );

        // Optimistic insert di atas (list urut desc by tgl & noqc; insert dulu, nanti refresh)
        _items.insert(0, created);

        // Refresh halaman aktif (biar meta.total/hasNext sinkron)
        await loadPage(_meta?.page ?? 1);

        _error = '';
        return true;
      } else {
        Map<String, dynamic>? map;
        try { map = respText.isNotEmpty ? jsonDecode(respText) : null; } catch (_) {}
        _error = map?['message']?.toString() ?? 'Server error (${resp.statusCode})';
        return false;
      }
    } catch (e, st) {
      _error = 'Koneksi/unknown error: $e';
      print('[QC-CREATE] exception: $e');
      print(st);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
      print('[QC-CREATE] done uri=$uri total=${sw.elapsedMilliseconds}ms err="$_error"');
    }
  }

}
