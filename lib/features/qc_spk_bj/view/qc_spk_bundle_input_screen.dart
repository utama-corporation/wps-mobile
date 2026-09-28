// lib/features/qc_spk_bj/view/qc_spk_bundle_input_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/app_toast.dart';
import '../model/qc_spk_bundle.dart';
import '../model/qc_spk_line.dart';
import '../view_model/qc_spk_bundle_view_model.dart';
import 'qc_photo_viewer_screen.dart';

const _brand = Color(0xFF755330);

/// Screen input 1 bundle QC (bukan bottom sheet). Simpan langsung per bundle.
/// Pop dengan `true` bila berhasil disimpan.
class QcSpkBundleInputScreen extends StatefulWidget {
  final QcSpkBundleViewModel vm;
  final QcSpkLine spec;
  final int noBundle;
  final QcSpkBundle? initial;

  const QcSpkBundleInputScreen({
    super.key,
    required this.vm,
    required this.spec,
    required this.noBundle,
    this.initial,
  });

  @override
  State<QcSpkBundleInputScreen> createState() => _QcSpkBundleInputScreenState();
}

class _QcSpkBundleInputScreenState extends State<QcSpkBundleInputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final TextEditingController _tebal;
  late final TextEditingController _lebar;
  late final TextEditingController _panjang;
  late final TextEditingController _pcs;

  // foto yang baru dipilih (menambah/menimpa foto lama saat disimpan)
  final List<File> _fotoTebal = [];
  final List<File> _fotoLebar = [];
  final List<File> _fotoPanjang = [];
  final List<File> _fotoBundle = [];

  // URL foto tersimpan (bisa berubah setelah dihapus)
  final List<String> _urlTebal = [];
  final List<String> _urlLebar = [];
  final List<String> _urlPanjang = [];
  final List<String> _urlBundle = [];

  bool _saving = false;
  bool _changed =
      false; // ada perubahan tersimpan -> beri tahu layar daftar saat kembali

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    final s = widget.spec;

    if (i != null) {
      _urlTebal.addAll(i.fotoTebalUrls);
      _urlLebar.addAll(i.fotoLebarUrls);
      _urlPanjang.addAll(i.fotoPanjangUrls);
      _urlBundle.addAll(i.fotoBundleUrls);
    }
    final filled = i != null &&
        i.tebal != null &&
        i.lebar != null &&
        i.panjang != null &&
        i.jumlahPcs != null;

    _tebal =
        TextEditingController(text: _numOrEmpty(filled ? i.tebal : s.tebal));
    _lebar =
        TextEditingController(text: _numOrEmpty(filled ? i.lebar : s.lebar));
    _panjang = TextEditingController(
        text: _numOrEmpty(filled ? i.panjang : s.panjang));
    _pcs = TextEditingController(
      text: filled
          ? i.jumlahPcs.toString()
          : (s.pcsPerBundle > 0 ? s.pcsPerBundle.toString() : ''),
    );
  }

  @override
  void dispose() {
    _tebal.dispose();
    _lebar.dispose();
    _panjang.dispose();
    _pcs.dispose();
    super.dispose();
  }

  String _numOrEmpty(double? n) =>
      n == null ? '' : (n % 1 == 0 ? n.toStringAsFixed(0) : n.toString());

  String? _validNum(String? v) {
    final d = double.tryParse((v ?? '').trim());
    if (d == null) return 'Wajib angka';
    if (d <= 0) return 'Harus > 0';
    return null;
  }

  String? _validInt(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Wajib angka';
    if (n <= 0) return 'Harus > 0';
    return null;
  }

  Future<void> _pickPhoto(
    String label,
    List<File> newFiles,
    List<String> savedUrls,
  ) async {
    if (_totalPhotos(newFiles, savedUrls) >= QcSpkBundle.maxPhotosPerField) {
      AppToast.warning(
        context,
        '$label sudah penuh (maks ${QcSpkBundle.maxPhotosPerField} foto)',
      );
      return;
    }
    // Wajib ambil real-time dari kamera — galeri tidak diperbolehkan.
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (x == null) return;
      if (!mounted) return;
      setState(() => newFiles.add(File(x.path)));
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal ambil foto: $e');
    }
  }

  int _totalPhotos(List<File> newFiles, List<String> savedUrls) =>
      newFiles.length + savedUrls.length;

  static void _replaceAll(List<String> target, List<String> src) {
    target
      ..clear()
      ..addAll(src);
  }

  /// Hapus 1 foto tersimpan di server pada [index] (dengan konfirmasi).
  Future<void> _deleteSavedPhoto(
    String field,
    String label,
    List<String> savedUrls,
    int index,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus foto?'),
        content: Text(
          '$label foto ${index + 1} akan dihapus permanen dari server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _saving = true);
    final ok =
        await widget.vm.deletePhoto(widget.noBundle, field, index: index);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      setState(() {
        savedUrls.removeAt(index);
        _changed = true;
      });
      AppToast.success(context, '$label foto ${index + 1} dihapus');
    } else {
      AppToast.error(
        context,
        widget.vm.error.isEmpty ? 'Gagal hapus foto' : widget.vm.error,
      );
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final bundle = QcSpkBundle(
      noBundle: widget.noBundle,
      tebal: double.tryParse(_tebal.text.trim()),
      lebar: double.tryParse(_lebar.text.trim()),
      panjang: double.tryParse(_panjang.text.trim()),
      jumlahPcs: int.tryParse(_pcs.text.trim()),
    );

    final ok = await widget.vm.saveOne(
      bundle,
      fotoTebal: _fotoTebal,
      fotoLebar: _fotoLebar,
      fotoPanjang: _fotoPanjang,
      fotoBundle: _fotoBundle,
    );
    if (!mounted) return;

    if (ok) {
      // tetap di layar ini; sinkronkan foto tersimpan & bersihkan pilihan baru
      final saved = widget.vm.items.firstWhere(
        (b) => b.noBundle == widget.noBundle,
        orElse: () => QcSpkBundle(noBundle: widget.noBundle),
      );
      setState(() {
        _saving = false;
        _changed = true;
        _replaceAll(_urlTebal, saved.fotoTebalUrls);
        _replaceAll(_urlLebar, saved.fotoLebarUrls);
        _replaceAll(_urlPanjang, saved.fotoPanjangUrls);
        _replaceAll(_urlBundle, saved.fotoBundleUrls);
        _fotoTebal.clear();
        _fotoLebar.clear();
        _fotoPanjang.clear();
        _fotoBundle.clear();
      });
      AppToast.success(context, 'Bundle #${widget.noBundle} tersimpan');
    } else {
      setState(() => _saving = false);
      AppToast.error(
        context,
        widget.vm.error.isEmpty ? 'Gagal menyimpan' : widget.vm.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spec;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: _brand,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Input Bundle #${widget.noBundle}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${s.namaBarangJadi ?? "Barang Jadi"} · ${s.dimensiLabel}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tebal,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _deco('Tebal'),
                      validator: _validNum,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lebar,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _deco('Lebar'),
                      validator: _validNum,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _panjang,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: _deco('Panjang'),
                      validator: _validNum,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pcs,
                      keyboardType: TextInputType.number,
                      decoration: _deco('Jumlah Pcs'),
                      validator: _validInt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Foto QC',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              Text(
                'Maksimal ${QcSpkBundle.maxPhotosPerField} foto per bidang.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 8),
              _photoSection('Foto Tebal', 'fotoTebal', _fotoTebal, _urlTebal),
              _photoSection('Foto Lebar', 'fotoLebar', _fotoLebar, _urlLebar),
              _photoSection(
                  'Foto Panjang', 'fotoPanjang', _fotoPanjang, _urlPanjang),
              _photoSection(
                  'Foto Bundle', 'fotoBundle', _fotoBundle, _urlBundle),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'Menyimpan...' : 'Simpan Bundle'),
              style: FilledButton.styleFrom(
                backgroundColor: _brand,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saving ? null : _save,
            ),
          ),
        ),
      ),
    );
  }

  /// Satu bidang foto: judul + jumlah terisi + [QcSpkBundle.maxPhotosPerField] slot.
  /// Foto tersimpan selalu tampil lebih dulu, foto baru menyusul di slot berikutnya.
  Widget _photoSection(
    String label,
    String field,
    List<File> newFiles,
    List<String> savedUrls,
  ) {
    final max = QcSpkBundle.maxPhotosPerField;
    final savedCount = savedUrls.length;
    final total = _totalPhotos(newFiles, savedUrls);

    final tiles = <Widget>[];
    for (var i = 0; i < max; i++) {
      final isSaved = i < savedCount;
      final newIdx = i - savedCount;
      tiles.add(Expanded(
        child: AspectRatio(
          aspectRatio: 1,
          child: _PhotoTile(
            label: label,
            index: i + 1,
            file: isSaved || newIdx < 0 || newIdx >= newFiles.length
                ? null
                : newFiles[newIdx],
            networkUrl: isSaved ? savedUrls[i] : null,
            onPick: () => _pickPhoto(label, newFiles, savedUrls),
            onClearNew: (!isSaved && newIdx >= 0 && newIdx < newFiles.length)
                ? () => setState(() => newFiles.removeAt(newIdx))
                : null,
            onDeleteSaved: isSaved
                ? () => _deleteSavedPhoto(field, label, savedUrls, i)
                : null,
          ),
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            Text(
              '$total / $max',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: total >= max ? _brand : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            tiles[0],
            const SizedBox(width: 8),
            tiles[1],
            const SizedBox(width: 8),
            tiles[2],
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  InputDecoration _deco(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _brand, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );
}

class _PhotoTile extends StatelessWidget {
  final String label;
  final int index; // nomor slot (1..max)
  final File? file;
  final String? networkUrl;
  final VoidCallback onPick;
  final VoidCallback? onClearNew; // batalkan foto baru yang belum disimpan
  final VoidCallback? onDeleteSaved; // hapus foto tersimpan di server

  const _PhotoTile({
    required this.label,
    required this.index,
    required this.file,
    required this.networkUrl,
    required this.onPick,
    required this.onClearNew,
    required this.onDeleteSaved,
  });

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color? bg}) {
    return Material(
      color: bg ?? Colors.black.withOpacity(0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = file != null || (networkUrl != null);
    final removeAction = onClearNew ?? onDeleteSaved;

    Widget image;
    if (file != null) {
      image = Image.file(file!, fit: BoxFit.cover);
    } else if (networkUrl != null) {
      image = Image.network(
        networkUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image_outlined)),
      );
    } else {
      image = const SizedBox.shrink();
    }

    return InkWell(
      // ada foto -> preview layar penuh; belum ada -> buka kamera
      onTap: hasImage
          ? () =>
              showQcPhoto(context, file: file, url: networkUrl, title: label)
          : onPick,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? _brand : Colors.grey.shade300,
            width: hasImage ? 1.4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasImage) image,
            // Nomor slot di kiri atas, tombol hapus di kanan atas.
            if (hasImage)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            if (hasImage && removeAction != null)
              Positioned(
                top: 4,
                right: 4,
                child: _circleBtn(Icons.delete_outline, removeAction,
                    bg: Colors.red.shade600.withOpacity(0.85)),
              ),
            if (!hasImage)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_outlined,
                      color: Colors.grey.shade500, size: 24),
                  const SizedBox(height: 4),
                  Text('Kamera',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                ],
              ),
            if (file != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  color: Colors.amber.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  alignment: Alignment.center,
                  child: const Text(
                    'BARU',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
