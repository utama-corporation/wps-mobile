// lib/features/proses_produksi/widgets/proses_produksi_report_pdf.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/api_constants.dart';
import '../model/proses_produksi_process.dart';

/// Unduh laporan PDF produksi (`GET /api/produksi/{proses}/report/{no}/pdf`)
/// lalu buka dialog print/preview dari plugin `printing`.
///
/// Endpoint laporan mewajibkan JWT (dipakai backend untuk mengisi kolom
/// "Print by"), jadi PDF diunduh dengan header Authorization — bukan dibuka
/// lewat url_launcher.
Future<void> openProsesProduksiReportPdf(
  BuildContext context,
  ProsesProduksiProcess process,
  String noProduksi,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 14),
              Text('Menyiapkan laporan...'),
            ],
          ),
        ),
      ),
    ),
  );

  Uint8List? bytes;
  String? error;

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final uri = Uri.parse(
      ApiConstants.prosesProduksiReportPdf(process.apiSegment, noProduksi),
    );

    final resp = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (resp.statusCode == 200) {
      bytes = resp.bodyBytes;
    } else if (resp.statusCode == 401 || resp.statusCode == 403) {
      error = resp.statusCode == 401
          ? 'Sesi Anda sudah berakhir. Silakan login kembali.'
          : 'Anda tidak punya akses untuk laporan ini.';
    } else {
      error = _message(resp) ?? 'Gagal memuat laporan (${resp.statusCode})';
    }
  } catch (e) {
    error = 'Koneksi/unknown error: $e';
  }

  navigator.pop(); // tutup dialog loading

  if (!context.mounted) return;

  if (bytes == null || bytes.isEmpty) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(error ?? 'Laporan kosong'),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  final data = bytes;
  await Printing.layoutPdf(
    onLayout: (_) async => data,
    name: 'ProsesProduksi${process.title}_$noProduksi.pdf',
  );
}

String? _message(http.Response resp) {
  if (resp.bodyBytes.isEmpty) return null;
  try {
    final decoded = json.decode(utf8.decode(resp.bodyBytes));
    if (decoded is Map && decoded['message'] != null) {
      return decoded['message'].toString();
    }
  } catch (_) {}
  return null;
}
