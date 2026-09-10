import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../model/mapping_lokasi_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_constants.dart';

class MappingLokasiViewModel extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Lokasi summary  (GET /api/mapping/lokasi-summary)
  // ---------------------------------------------------------------------------
  List<LokasiSummaryModel> lokasiSummaryList = [];
  bool isSummaryLoading = false;
  String summaryError = '';

  // ---------------------------------------------------------------------------
  // Label per lokasi  (GET /api/mapping/lokasi-labels?idlokasi=...)
  // ---------------------------------------------------------------------------
  List<LokasiLabelModel> labelList = [];
  bool isLabelLoading = false;
  String labelError = '';
  int totalLabelData = 0;
  int totalJumlah = 0;
  String totalTon = '0.0000';
  String totalM3 = '0.0000';
  String? currentIdLokasi;

  // ---------------------------------------------------------------------------
  // Scan / update lokasi
  // ---------------------------------------------------------------------------
  bool isSaving = false;
  String saveMessage = '';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<void> fetchLokasiSummary() async {
    isSummaryLoading = true;
    summaryError = '';
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        summaryError = 'Token tidak ditemukan. Harap login ulang.';
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.mappingLokasiSummary),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rows = data['data'] ?? [];
        lokasiSummaryList =
            rows.map((e) => LokasiSummaryModel.fromJson(e)).toList();
        summaryError = '';
      } else {
        summaryError =
            'Gagal memuat lokasi (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      summaryError = 'Error: $e';
    } finally {
      isSummaryLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLokasiLabels(String idLokasi) async {
    isLabelLoading = true;
    labelError = '';
    currentIdLokasi = idLokasi;
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null) {
        labelError = 'Token tidak ditemukan. Harap login ulang.';
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.mappingLokasiLabels(idLokasi)),
        headers: _headers(token),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rows = data['data'] ?? [];
        labelList = rows.map((e) => LokasiLabelModel.fromJson(e)).toList();
        totalLabelData = data['totalData'] ?? labelList.length;
        final summary = data['summary'] ?? {};
        totalJumlah = summary['totalJumlah'] ?? 0;
        totalTon = summary['totalTon']?.toString() ?? '0.0000';
        totalM3 = summary['totalM3']?.toString() ?? '0.0000';
        labelError = '';
      } else {
        labelError =
            'Gagal memuat label (${response.statusCode}): ${response.body}';
      }
    } catch (e) {
      labelError = 'Error: $e';
    } finally {
      isLabelLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCurrentLokasiLabels() async {
    if (currentIdLokasi != null) {
      await fetchLokasiLabels(currentIdLokasi!);
    }
  }

  /// Cek satu label sebelum disimpan (POST /api/label-list/check).
  Future<void> processScannedCode(
    String scannedCode,
    String idLokasi, {
    Function(bool, int, String)? onSaveComplete,
  }) async {
    isSaving = true;
    saveMessage = 'Menyimpan...';
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        saveMessage = 'Token tidak ditemukan. Silakan login ulang.';
        onSaveComplete?.call(false, 401, saveMessage);
        return;
      }
      if (idLokasi.isEmpty) {
        saveMessage = 'IdLokasi tidak boleh kosong.';
        onSaveComplete?.call(false, 400, saveMessage);
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.checkLabel),
        headers: _headers(token),
        body: jsonEncode({
          'resultscanned': scannedCode,
          'idlokasi': idLokasi,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        saveMessage = 'Data berhasil disimpan!';
        onSaveComplete?.call(true, response.statusCode, saveMessage);
      } else {
        final responseJson = jsonDecode(response.body);
        saveMessage = responseJson['message'] ?? 'Gagal menyimpan';
        onSaveComplete?.call(false, response.statusCode, saveMessage);
      }
    } catch (e) {
      saveMessage = 'Terjadi kesalahan: $e';
      onSaveComplete?.call(false, 500, saveMessage);
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Simpan perubahan lokasi untuk kumpulan label hasil scan
  /// (POST /api/label-list/save-changes).
  Future<void> updateScannedCode(
    List<String> scannedCodes,
    String idLokasi, {
    Function(bool, int, String)? onSaveComplete,
  }) async {
    isSaving = true;
    saveMessage = 'Menyimpan...';
    notifyListeners();

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        saveMessage = 'Token tidak ditemukan. Silakan login ulang.';
        onSaveComplete?.call(false, 401, saveMessage);
        return;
      }
      if (idLokasi.isEmpty) {
        saveMessage = 'IdLokasi tidak boleh kosong.';
        onSaveComplete?.call(false, 400, saveMessage);
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.saveChanges),
        headers: _headers(token),
        body: jsonEncode({
          'resultscannedList': scannedCodes,
          'idlokasi': idLokasi,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        saveMessage = 'Data berhasil disimpan!';
        onSaveComplete?.call(true, response.statusCode, saveMessage);
      } else {
        final responseJson = jsonDecode(response.body);
        saveMessage = responseJson['message'] ?? 'Gagal menyimpan';
        onSaveComplete?.call(false, response.statusCode, saveMessage);
      }
    } catch (e) {
      saveMessage = 'Terjadi kesalahan: $e';
      onSaveComplete?.call(false, 500, saveMessage);
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
