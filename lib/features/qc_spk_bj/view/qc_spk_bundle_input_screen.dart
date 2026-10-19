// lib/features/qc_spk_bj/view/qc_spk_bundle_input_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/widgets/app_toast.dart';
import '../model/qc_spk_bundle.dart';
import '../model/qc_spk_line.dart';
import '../view_model/qc_spk_bundle_view_model.dart';
import 'qc_photo_viewer_screen.dart';

const _brand = Color(0xFF2E6F5D);

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

  // Nomor kolom DB tiap foto yang tampil (urutan: foto tersimpan lalu foto
  // baru). Dipakai agar keterangan dikirim ke kolom yang benar.
  final List<int> _slotTebal = [];
  final List<int> _slotLebar = [];
  final List<int> _slotPanjang = [];
  final List<int> _slotBundle = [];

  // caption/keterangan per slot foto (satu per foto, sejajar urutan slot).
  late final List<TextEditingController> _ketTebal;
  late final List<TextEditingController> _ketLebar;
  late final List<TextEditingController> _ketPanjang;
  late final List<TextEditingController> _ketBundle;

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
      _slotTebal.addAll(i.fotoTebalSlots);
      _slotLebar.addAll(i.fotoLebarSlots);
      _slotPanjang.addAll(i.fotoPanjangSlots);
      _slotBundle.addAll(i.fotoBundleSlots);
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

    final n = QcSpkBundle.maxPhotosPerField;
    _ketTebal = _buildCaptions(i?.fotoTebalCaptions, n, fallback: '0');
    _ketLebar = _buildCaptions(i?.fotoLebarCaptions, n, fallback: '0');
    _ketPanjang = _buildCaptions(i?.fotoPanjangCaptions, n, fallback: '0');
    _ketBundle = _buildCaptions(
      i?.fotoBundleCaptions,
      QcSpkBundle.maxBundlePhotos,
      fallback: '0',
    );
  }

  @override
  void dispose() {
    _tebal.dispose();
    _lebar.dispose();
    _panjang.dispose();
    _pcs.dispose();
    for (final c in _ketTebal) {
      c.dispose();
    }
    for (final c in _ketLebar) {
      c.dispose();
    }
    for (final c in _ketPanjang) {
      c.dispose();
    }
    for (final c in _ketBundle) {
      c.dispose();
    }
    super.dispose();
  }

  /// [n] controller nilai; diisi dari hasil ukur yang sudah tersimpan, dan
  /// memakai [fallback] bila slot foto itu belum punya nilai.
  static List<TextEditingController> _buildCaptions(
    List<String>? src,
    int n, {
    String fallback = '',
  }) =>
      List.generate(
        n,
        (k) => TextEditingController(
          text: (src != null && k < src.length && src[k].trim().isNotEmpty)
              ? src[k]
              : fallback,
        ),
      );

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
    List<int> slots,
    int max,
  ) async {
    if (_totalPhotos(newFiles, savedUrls) >= max) {
      AppToast.warning(context, '$label sudah penuh (maks $max foto)');
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
      setState(() {
        newFiles.add(File(x.path));
        // server akan menaruh foto baru di kolom kosong pertama
        slots.add(_nextFreeSlot(slots, max));
      });
    } catch (e) {
      if (mounted) AppToast.error(context, 'Gagal ambil foto: $e');
    }
  }

  /// Kolom kosong pertama pada [used]; -1 bila sudah penuh.
  static int _nextFreeSlot(List<int> used, int max) {
    for (var s = 0; s < max; s++) {
      if (!used.contains(s)) return s;
    }
    return -1;
  }

  /// Keterangan diurutkan per KOLOM DB, bukan per posisi tampilan, supaya
  /// tetap menempel pada foto yang benar setelah ada foto tengah dihapus.
  static List<String> _captionsByColumn(
    List<int> slots,
    List<TextEditingController> caps,
    int max,
  ) {
    final out = List<String>.filled(max, '');
    for (var p = 0; p < slots.length && p < caps.length; p++) {
      final s = slots[p];
      if (s >= 0 && s < max) out[s] = caps[p].text.trim();
    }
    return out;
  }

  int _totalPhotos(List<File> newFiles, List<String> savedUrls) =>
      newFiles.length + savedUrls.length;

  /// Hanya angka dengan maksimal satu pemisah desimal (`,` dinormalkan ke `.`).
  static final _digitsOnly = TextInputFormatter.withFunction((old, next) {
    final cleaned = next.text.replaceAll(',', '.').replaceAll(
          RegExp(r'[^0-9.]'),
          '',
        );
    final parts = cleaned.split('.');
    final out = parts.length > 1
        ? '${parts.first}.${parts.sublist(1).join()}'
        : cleaned;
    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: out.length),
    );
  });

  static void _replaceAll<T>(List<T> target, List<T> src) {
    target
      ..clear()
      ..addAll(src);
  }

  static void _replaceCaps(
    List<TextEditingController> target,
    List<String> src, {
    String fallback = '',
  }) {
    for (var i = 0; i < target.length; i++) {
      final v = i < src.length ? src[i] : '';
      target[i].text = v.trim().isEmpty ? fallback : v;
    }
  }

  /// Setelah foto pada posisi [from] dihapus, semua foto berikutnya maju satu
  /// slot — jadi teks keterangan ikut naik agar tetap menempel pada fotonya.
  static void _shiftCapsDown(
    List<TextEditingController> caps,
    int from,
    String fallback,
  ) {
    for (var k = from; k < caps.length - 1; k++) {
      caps[k].text = caps[k + 1].text;
    }
    if (caps.isNotEmpty) caps.last.text = fallback;
  }

  /// Hapus 1 foto tersimpan di server pada [index] (dengan konfirmasi).
  Future<void> _deleteSavedPhoto(
    String field,
    String label,
    List<String> savedUrls,
    List<int> slots,
    int index,
    List<TextEditingController> captions,
    String fallback,
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
        if (index < slots.length) slots.removeAt(index);
        _shiftCapsDown(captions, index, fallback);
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
      captions: {
        'fotoTebal': _captionsByColumn(
            _slotTebal, _ketTebal, QcSpkBundle.maxPhotosPerField),
        'fotoLebar': _captionsByColumn(
            _slotLebar, _ketLebar, QcSpkBundle.maxPhotosPerField),
        'fotoPanjang': _captionsByColumn(
            _slotPanjang, _ketPanjang, QcSpkBundle.maxPhotosPerField),
        'fotoBundle': _captionsByColumn(
            _slotBundle, _ketBundle, QcSpkBundle.maxBundlePhotos),
      },
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
        _replaceAll(_slotTebal, saved.fotoTebalSlots);
        _replaceAll(_slotLebar, saved.fotoLebarSlots);
        _replaceAll(_slotPanjang, saved.fotoPanjangSlots);
        _replaceAll(_slotBundle, saved.fotoBundleSlots);
        _replaceCaps(_ketTebal, saved.fotoTebalCaptions, fallback: '0');
        _replaceCaps(_ketLebar, saved.fotoLebarCaptions, fallback: '0');
        _replaceCaps(
            _ketPanjang, saved.fotoPanjangCaptions, fallback: '0');
        _replaceCaps(_ketBundle, saved.fotoBundleCaptions, fallback: '0');
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
                'Maksimal ${QcSpkBundle.maxPhotosPerField} foto untuk '
                'tebal/lebar/panjang dan ${QcSpkBundle.maxBundlePhotos} foto '
                'untuk bundle.\nIsi angka hasil ukur pada kolom di bawah '
                'setiap foto.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 8),
              _photoSection(
                'Foto Tebal',
                'fotoTebal',
                _fotoTebal,
                _urlTebal,
                _slotTebal,
                _ketTebal,
                max: QcSpkBundle.maxPhotosPerField,
                valueHint: 'Tebal (mm)',
              ),
              _photoSection(
                'Foto Lebar',
                'fotoLebar',
                _fotoLebar,
                _urlLebar,
                _slotLebar,
                _ketLebar,
                max: QcSpkBundle.maxPhotosPerField,
                valueHint: 'Lebar (mm)',
              ),
              _photoSection(
                'Foto Panjang',
                'fotoPanjang',
                _fotoPanjang,
                _urlPanjang,
                _slotPanjang,
                _ketPanjang,
                max: QcSpkBundle.maxPhotosPerField,
                valueHint: 'Panjang (mm)',
              ),
              _photoSection(
                'Foto Bundle',
                'fotoBundle',
                _fotoBundle,
                _urlBundle,
                _slotBundle,
                _ketBundle,
                max: QcSpkBundle.maxBundlePhotos,
                valueHint: 'Pcs',
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

  /// Satu bidang foto: judul + jumlah terisi + [max] slot.
  /// Foto tersimpan selalu tampil lebih dulu, foto baru menyusul di slot berikutnya.
  /// Bila [valueHint] diisi, setiap foto yang terisi punya satu kolom angka
  /// (hasil ukur) di bawahnya. [captions] = controller per slot.
  Widget _photoSection(
    String label,
    String field,
    List<File> newFiles,
    List<String> savedUrls,
    List<int> slots,
    List<TextEditingController> captions, {
    required int max,
    String valueHint = '',
    String fallback = '0',
  }) {
    final savedCount = savedUrls.length;
    final total = _totalPhotos(newFiles, savedUrls);
    final showValue = valueHint.isNotEmpty;

    final columns = <Widget>[];
    for (var i = 0; i < max; i++) {
      final isSaved = i < savedCount;
      final newIdx = i - savedCount;
      final filled = isSaved || (newIdx >= 0 && newIdx < newFiles.length);

      columns.add(Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: _PhotoTile(
                label: label,
                index: i + 1,
                file: filled && !isSaved ? newFiles[newIdx] : null,
                networkUrl: isSaved ? savedUrls[i] : null,
                onPick: () =>
                    _pickPhoto(label, newFiles, savedUrls, slots, max),
                onClearNew: filled && !isSaved
                    ? () => setState(() {
                          newFiles.removeAt(newIdx);
                          if (i < slots.length) slots.removeAt(i);
                          _shiftCapsDown(captions, i, fallback);
                        })
                    : null,
                onDeleteSaved: isSaved
                    ? () => _deleteSavedPhoto(field, label, savedUrls, slots, i,
                        captions, fallback)
                    : null,
              ),
            ),
            if (filled && showValue) ...[
              const SizedBox(height: 6),
              TextFormField(
                controller: captions[i],
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                inputFormatters: [_digitsOnly],
                decoration: InputDecoration(
                  hintText: valueHint,
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: _brand, width: 1.4),
                  ),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
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
            for (var i = 0; i < columns.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              columns[i],
            ],
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
