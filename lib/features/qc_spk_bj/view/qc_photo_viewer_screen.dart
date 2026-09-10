// lib/features/qc_spk_bj/view/qc_photo_viewer_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';

/// Preview foto layar penuh dengan pinch-zoom. Tap / tombol back untuk keluar.
class QcPhotoViewerScreen extends StatelessWidget {
  final File? file;
  final String? url;
  final String? title;

  const QcPhotoViewerScreen({super.key, this.file, this.url, this.title});

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (file != null) {
      img = Image.file(file!, fit: BoxFit.contain);
    } else if (url != null) {
      img = Image.network(
        url!,
        fit: BoxFit.contain,
        loadingBuilder: (ctx, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(color: Colors.white)),
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image_outlined,
              color: Colors.white54, size: 56),
        ),
      );
    } else {
      img = const Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: Colors.white54, size: 56),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: title == null
            ? null
            : Text(title!, style: const TextStyle(fontSize: 15)),
      ),
      body: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Center(child: img),
        ),
      ),
    );
  }
}

Future<void> showQcPhoto(
  BuildContext context, {
  File? file,
  String? url,
  String? title,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => QcPhotoViewerScreen(file: file, url: url, title: title),
    ),
  );
}
