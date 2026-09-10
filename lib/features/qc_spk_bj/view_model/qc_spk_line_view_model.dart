// lib/features/qc_spk_bj/view_model/qc_spk_line_view_model.dart
import 'dart:convert' show jsonDecode, utf8;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../model/qc_spk_line.dart';

/// Daftar baris detail (MstSPK_d) untuk 1 SPK + progress QC per baris.
class QcSpkLineViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String _error = '';
  List<QcSpkLine> _items = [];
  String _noSPK = '';

  bool get isLoading => _isLoading;
  String get error => _error;
  List<QcSpkLine> get items => List.unmodifiable(_items);
  String get noSPK => _noSPK;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> load(String noSPK) async {
    _noSPK = noSPK;
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
        _error = 'Unauthorized: no token';
        return;
      }

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/api/qc-spk-bj/${Uri.encodeComponent(_noSPK)}/lines',
      );

      final resp = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      final bodyStr = utf8.decode(resp.bodyBytes);

      if (resp.statusCode == 200) {
        final body = jsonDecode(bodyStr) as Map<String, dynamic>;
        if (body['success'] != true) {
          _error = body['message']?.toString() ?? 'Gagal memuat baris SPK';
          return;
        }
        final List raw = body['data'] as List? ?? const [];
        _items = raw
            .map((e) => QcSpkLine.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _error = '';
      } else if (resp.statusCode == 404) {
        _items = [];
        _error = '';
      } else if (resp.statusCode == 401) {
        _error = 'Unauthorized: Token invalid/expired';
      } else {
        _error = 'Server error (${resp.statusCode})';
      }
    } catch (e) {
      _error = 'Koneksi/unknown error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
