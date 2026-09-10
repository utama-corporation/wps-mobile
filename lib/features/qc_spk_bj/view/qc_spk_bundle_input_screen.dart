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

  // foto yang baru dipilih (menimpa foto lama saat disimpan)
  File? _fotoTebal;
  File? _fotoLebar;
  File? _fotoPanjang;
  File? _fotoBundle;

  // URL foto tersimpan (bisa berubah null setelah dihapus)
  String? _urlTebal;
  String? _urlLebar;
  String? _urlPanjang;
  String? _urlBundle;

  bool _saving = false;
  bool _changed =
      false; // ada perubahan tersimpan -> beri tahu layar daftar saat kembali

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    final s = widget.spec;

    _urlTebal = i?.fotoTebalUrl;
    _urlLebar = i?.fotoLebarUrl;
    _urlPanjang = i?.fotoPanjangUrl;
    _urlBundle = i?.fotoBundleUrl;
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

  Future<void> _pickPhoto(void Function(File) onPicked) async {
    // Wajib ambil real-time dari kamera — galeri tidak diperbolehkan.
    try {
      final x = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (x != null) setState(() => onPicked(File(x.path)));
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal ambil foto: $e');
    }
  }

  /// Hapus foto tersimpan di server (dengan konfirmasi).
  Future<void> _deleteSavedPhoto(
    String field,
    String label,
    void Function() clearLocalUrl,
  ) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus foto?'),
        content: Text('$label akan dihapus permanen dari server.'),
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
    final ok = await widget.vm.deletePhoto(widget.noBundle, field);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      setState(() {
        clearLocalUrl();
        _changed = true;
      });
      AppToast.success(context, '$label dihapus');
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
        _urlTebal = saved.fotoTebalUrl;
        _urlLebar = saved.fotoLebarUrl;
        _urlPanjang = saved.fotoPanjangUrl;
        _urlBundle = saved.fotoBundleUrl;
        _fotoTebal = null;
        _fotoLebar = null;
        _fotoPanjang = null;
        _fotoBundle = null;
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
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
                children: [
                  _PhotoTile(
                    label: 'Foto Tebal',
                    file: _fotoTebal,
                    networkUrl: _urlTebal,
                    onPick: () => _pickPhoto((f) => _fotoTebal = f),
                    onClearNew: _fotoTebal == null
                        ? null
                        : () => setState(() => _fotoTebal = null),
                    onDeleteSaved: (_fotoTebal == null && _urlTebal != null)
                        ? () => _deleteSavedPhoto(
                            'fotoTebal', 'Foto Tebal', () => _urlTebal = null)
                        : null,
                  ),
                  _PhotoTile(
                    label: 'Foto Lebar',
                    file: _fotoLebar,
                    networkUrl: _urlLebar,
                    onPick: () => _pickPhoto((f) => _fotoLebar = f),
                    onClearNew: _fotoLebar == null
                        ? null
                        : () => setState(() => _fotoLebar = null),
                    onDeleteSaved: (_fotoLebar == null && _urlLebar != null)
                        ? () => _deleteSavedPhoto(
                            'fotoLebar', 'Foto Lebar', () => _urlLebar = null)
                        : null,
                  ),
                  _PhotoTile(
                    label: 'Foto Panjang',
                    file: _fotoPanjang,
                    networkUrl: _urlPanjang,
                    onPick: () => _pickPhoto((f) => _fotoPanjang = f),
                    onClearNew: _fotoPanjang == null
                        ? null
                        : () => setState(() => _fotoPanjang = null),
                    onDeleteSaved: (_fotoPanjang == null && _urlPanjang != null)
                        ? () => _deleteSavedPhoto('fotoPanjang', 'Foto Panjang',
                            () => _urlPanjang = null)
                        : null,
                  ),
                  _PhotoTile(
                    label: 'Foto Bundle',
                    file: _fotoBundle,
                    networkUrl: _urlBundle,
                    onPick: () => _pickPhoto((f) => _fotoBundle = f),
                    onClearNew: _fotoBundle == null
                        ? null
                        : () => setState(() => _fotoBundle = null),
                    onDeleteSaved: (_fotoBundle == null && _urlBundle != null)
                        ? () => _deleteSavedPhoto('fotoBundle', 'Foto Bundle',
                            () => _urlBundle = null)
                        : null,
                  ),
                ],
              ),
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
  final File? file;
  final String? networkUrl;
  final VoidCallback onPick;
  final VoidCallback? onClearNew; // batalkan foto baru yang belum disimpan
  final VoidCallback? onDeleteSaved; // hapus foto tersimpan di server

  const _PhotoTile({
    required this.label,
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
            // Sudah ada foto: hanya tombol HAPUS. Untuk ganti foto:
            // hapus dulu, lalu ambil ulang dari tile kosong.
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
                      color: Colors.grey.shade500, size: 26),
                  const SizedBox(height: 6),
                  Text(label,
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('Ambil dari kamera',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                ],
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.45),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (file != null)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Text('BARU',
                            style: TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
