// lib/features/qc_spk_bj/view_model/qc_spk_header_view_model.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../../../core/models/paginated_response_model.dart';
import '../../../core/models/pagination_meta_model.dart';
import '../model/qc_spk_header.dart';

/// Daftar SPK Barang Jadi (read-only) untuk proses QC.
class QcSpkHeaderViewModel extends ChangeNotifier {
  final List<QcSpkHeader> _items = [];
  PaginationMeta? _meta;

  bool _isLoading = false;
  String _error = '';

  String _q = '';

  List<QcSpkHeader> get items => List.unmodifiable(_items);
  PaginationMeta? get meta => _meta;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get canLoadMore => (_meta?.hasNext ?? false) && !_isLoading;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void setSearch(String q) => _q = q.trim();

  Future<void> refreshFirstPage({int pageSize = 20}) async {
    _items.clear();
    _meta = null;
    _error = '';
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

      final uri = Uri.parse('${ApiConstants.baseUrl}/api/qc-spk-bj').replace(
        queryParameters: {
          'page': page.toString(),
          'pageSize': pageSize.toString(),
          if (_q.isNotEmpty) 'q': _q,
        },
      );

      final resp =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});

      if (resp.statusCode == 200) {
        final Map<String, dynamic> body =
            jsonDecode(utf8.decode(resp.bodyBytes));
        if (body['success'] != true) {
          _error = body['message']?.toString() ?? 'Gagal memuat data';
          return;
        }

        final parsed = PaginatedResponse<QcSpkHeader>.fromJson(
          body,
          (m) => QcSpkHeader.fromJson(m),
        );
        _meta = parsed.meta;

        if (append) {
          _items.addAll(parsed.data);
        } else {
          _items
            ..clear()
            ..addAll(parsed.data);
        }
        _error = '';
      } else if (resp.statusCode == 401) {
        _error = 'Unauthorized: Token invalid/expired';
      } else {
        String? serverMessage;
        final raw = resp.body.trim();
        if (raw.isNotEmpty) {
          try {
            final decoded = jsonDecode(raw);
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
}
