// lib/features/qc_spk_bj/view_model/qc_spk_bundle_view_model.dart
import 'dart:convert' show jsonDecode, jsonEncode, utf8;
import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../model/qc_spk_bundle.dart';

/// Bundle QC untuk 1 baris SPK. Simpan = replace-all (overwrite=true).
class QcSpkBundleViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String _error = '';
  List<QcSpkBundle> _items = [];
  String _noSPK = '';
  int _lineNo = 0;

  bool get isLoading => _isLoading;
  String get error => _error;
  List<QcSpkBundle> get items => List.unmodifiable(_items);
  String get noSPK => _noSPK;
  int get lineNo => _lineNo;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  String get _baseUri =>
      '${ApiConstants.baseUrl}/api/qc-spk-bj/${Uri.encodeComponent(_noSPK)}/lines/$_lineNo/bundles';

  Future<void> load(String noSPK, int lineNo) async {
    _noSPK = noSPK;
    _lineNo = lineNo;
    _error = '';
    _items = [];
    await _fetch();
  }

  Future<void> refresh() => _fetch();

  Future<void> _fetch() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        _setError('Unauthorized: no token');
        return;
      }

      final resp = await http.get(
        Uri.parse(_baseUri),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      final bodyStr = utf8.decode(resp.bodyBytes);

      if (resp.statusCode == 200) {
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;
        if (body['success'] != true) {
          _setError(body['message']?.toString() ?? 'Gagal memuat bundle QC');
          return;
        }
        final List raw = body['data'] as List? ?? const [];
        // JANGAN renumber — noBundle dari server adalah sumber kebenaran.
        _items = raw
            .map((e) =>
                QcSpkBundle.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => (a.noBundle ?? 0).compareTo(b.noBundle ?? 0));
        _error = '';
      } else if (resp.statusCode == 404) {
        _items = [];
        _error = '';
      } else if (resp.statusCode == 401) {
        _setError('Unauthorized: Token invalid/expired');
      } else {
        _setError('Server error (${resp.statusCode})');
      }
    } catch (e) {
      _setError('Koneksi/unknown error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Simpan seluruh grid (replace-all). [items] akan dinormalisasi noBundle 1..N.
  Future<bool> replaceAll(List<QcSpkBundle> items) async {
    final normalized = _normalize(items);
    return _post(normalized, overwrite: true);
  }

  Future<bool> _post(List<QcSpkBundle> items, {required bool overwrite}) async {
    if (_noSPK.isEmpty || _lineNo < 1) {
      _setError('SPK/baris belum di-set. Panggil load() dulu.');
      return false;
    }
    try {
      final token = await _getToken();
      if (token == null) {
        _setError('Unauthorized: no token');
        return false;
      }

      final payload = {
        'overwrite': overwrite,
        'items': items.map((e) => e.toPostMap()).toList(),
      };

      final resp = await http
          .post(
            Uri.parse(_baseUri),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _fetch();
        return true;
      }

      final body = _safeBodyMap(resp.bodyBytes);
      _setError(body['message']?.toString() ?? 'Gagal simpan (${resp.statusCode})');
      return false;
    } catch (e) {
      _setError('Gagal simpan: $e');
      return false;
    }
  }

  /// Simpan 1 bundle (upsert) + foto opsional — via multipart PUT .../bundles/:noBundle.
  Future<bool> saveOne(
    QcSpkBundle bundle, {
    File? fotoTebal,
    File? fotoLebar,
    File? fotoPanjang,
    File? fotoBundle,
  }) async {
    if (_noSPK.isEmpty || _lineNo < 1) {
      _setError('SPK/baris belum di-set. Panggil load() dulu.');
      return false;
    }
    final noBundle = bundle.noBundle;
    if (noBundle == null || noBundle < 1) {
      _setError('noBundle tidak valid.');
      return false;
    }
    try {
      final token = await _getToken();
      if (token == null) {
        _setError('Unauthorized: no token');
        return false;
      }

      final req = http.MultipartRequest('PUT', Uri.parse('$_baseUri/$noBundle'))
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..fields['tebal'] = '${bundle.tebal ?? ''}'
        ..fields['lebar'] = '${bundle.lebar ?? ''}'
        ..fields['panjang'] = '${bundle.panjang ?? ''}'
        ..fields['jumlahPcs'] = '${bundle.jumlahPcs ?? ''}';

      Future<void> addFile(String field, File? f) async {
        if (f == null) return;
        req.files.add(await http.MultipartFile.fromPath(field, f.path));
      }

      await addFile('fotoTebal', fotoTebal);
      await addFile('fotoLebar', fotoLebar);
      await addFile('fotoPanjang', fotoPanjang);
      await addFile('fotoBundle', fotoBundle);

      final streamed = await req.send().timeout(const Duration(seconds: 60));
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _fetch();
        return true;
      }

      final body = _safeBodyMap(resp.bodyBytes);
      _setError(body['message']?.toString() ?? 'Gagal simpan (${resp.statusCode})');
      return false;
    } catch (e) {
      _setError('Gagal simpan: $e');
      return false;
    }
  }

  /// Hapus 1 foto tersimpan dari sebuah bundle.
  /// [field] = fotoTebal | fotoLebar | fotoPanjang | fotoBundle
  Future<bool> deletePhoto(int noBundle, String field) async {
    if (_noSPK.isEmpty || _lineNo < 1) {
      _setError('SPK/baris belum di-set.');
      return false;
    }
    try {
      final token = await _getToken();
      if (token == null) {
        _setError('Unauthorized: no token');
        return false;
      }
      final resp = await http.delete(
        Uri.parse('$_baseUri/$noBundle/photos/$field'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        await _fetch();
        return true;
      }
      final body = _safeBodyMap(resp.bodyBytes);
      _setError(body['message']?.toString() ?? 'Gagal hapus foto (${resp.statusCode})');
      return false;
    } catch (e) {
      _setError('Gagal hapus foto: $e');
      return false;
    }
  }

  /// Hapus 1 bundle QC (beserta foto MinIO di server).
  Future<bool> deleteOne(int noBundle) async {
    if (_noSPK.isEmpty || _lineNo < 1) {
      _setError('SPK/baris belum di-set. Panggil load() dulu.');
      return false;
    }
    if (noBundle < 1) {
      _setError('noBundle tidak valid.');
      return false;
    }
    try {
      final token = await _getToken();
      if (token == null) {
        _setError('Unauthorized: no token');
        return false;
      }

      final resp = await http.delete(
        Uri.parse('$_baseUri/$noBundle'),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        await _fetch();
        return true;
      }

      final body = _safeBodyMap(resp.bodyBytes);
      _setError(body['message']?.toString() ?? 'Gagal hapus bundle (${resp.statusCode})');
      return false;
    } catch (e) {
      _setError('Gagal hapus bundle: $e');
      return false;
    }
  }

  /// Hapus semua bundle QC untuk baris ini.
  Future<bool> deleteAll() async {
    if (_noSPK.isEmpty || _lineNo < 1) {
      _setError('SPK/baris belum di-set. Panggil load() dulu.');
      return false;
    }
    try {
      final token = await _getToken();
      if (token == null) {
        _setError('Unauthorized: no token');
        return false;
      }

      final resp = await http.delete(
        Uri.parse(_baseUri),
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      if (resp.statusCode == 200 || resp.statusCode == 204) {
        await _fetch();
        return true;
      }
      if (resp.statusCode == 404) {
        return _post(const [], overwrite: true);
      }

      final body = _safeBodyMap(resp.bodyBytes);
      _setError(body['message']?.toString() ?? 'Gagal hapus (${resp.statusCode})');
      return false;
    } catch (e) {
      _setError('Gagal hapus: $e');
      return false;
    }
  }

  // ---------- helpers ----------
  /// Sort by noBundle asc lalu set 1..N. Menghasilkan list baru.
  List<QcSpkBundle> _normalize(List<QcSpkBundle> src) {
    if (src.isEmpty) return const [];
    final sorted = [...src]
      ..sort((a, b) => (a.noBundle ?? 0).compareTo(b.noBundle ?? 0));
    final out = <QcSpkBundle>[];
    for (var i = 0; i < sorted.length; i++) {
      out.add(sorted[i].copyWith(noBundle: i + 1));
    }
    return out;
  }

  Map<String, dynamic> _safeBodyMap(List<int> bytes) {
    try {
      final m = jsonDecode(utf8.decode(bytes));
      return (m is Map<String, dynamic>) ? m : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  void _setError(String msg) {
    _error = msg;
    notifyListeners();
  }
}
