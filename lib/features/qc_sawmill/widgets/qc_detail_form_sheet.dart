import 'package:flutter/material.dart';
import '../model/qc_sawmill_detail.dart';

Future<QcSawmillDetail?> showQcDetailFormSheet(
    BuildContext context, {
      QcSawmillDetail? initial,
      int? suggestedNoUrut,
    }) {
  return showModalBottomSheet<QcSawmillDetail>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QcDetailFormSheet(
      initial: initial,
      suggestedNoUrut: suggestedNoUrut,
    ),
  );
}

class _QcDetailFormSheet extends StatefulWidget {
  final QcSawmillDetail? initial;
  final int? suggestedNoUrut;

  const _QcDetailFormSheet({
    required this.initial,
    this.suggestedNoUrut,
  });

  @override
  State<_QcDetailFormSheet> createState() => _QcDetailFormSheetState();
}

class _QcDetailFormSheetState extends State<_QcDetailFormSheet> {
  final _formKey = GlobalKey<FormState>();

  int? _noUrutVal;

  late final TextEditingController _cutTebal;
  late final TextEditingController _cutLebar;
  late final TextEditingController _actTebal;
  late final TextEditingController _actLebar;
  late final TextEditingController _susTebal;
  late final TextEditingController _susLebar;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _noUrutVal = i?.noUrut ?? widget.suggestedNoUrut;

    _cutTebal = TextEditingController(text: _numOrEmpty(i?.cuttingTebal));
    _cutLebar = TextEditingController(text: _numOrEmpty(i?.cuttingLebar));
    _actTebal = TextEditingController(text: _numOrEmpty(i?.actualTebal));
    _actLebar = TextEditingController(text: _numOrEmpty(i?.actualLebar));
    _susTebal = TextEditingController(text: _numOrEmpty(i?.susutTebal));
    _susLebar = TextEditingController(text: _numOrEmpty(i?.susutLebar));

    // Tambahkan listener agar susut otomatis dihitung
    _cutTebal.addListener(_recalcSusut);
    _cutLebar.addListener(_recalcSusut);
    _actTebal.addListener(_recalcSusut);
    _actLebar.addListener(_recalcSusut);
  }

  @override
  void dispose() {
    _cutTebal.dispose();
    _cutLebar.dispose();
    _actTebal.dispose();
    _actLebar.dispose();
    _susTebal.dispose();
    _susLebar.dispose();
    super.dispose();
  }

  // Helper konversi dan format angka
  String _numOrEmpty(double? n) =>
      n == null ? '' : (n % 1 == 0 ? n.toStringAsFixed(0) : n.toString());
  double? _toD(String s) => double.tryParse(s.trim());

  // Hitung ulang susut
  void _recalcSusut() {
    final cutT = _toD(_cutTebal.text) ?? 0;
    final actT = _toD(_actTebal.text) ?? 0;
    final cutL = _toD(_cutLebar.text) ?? 0;
    final actL = _toD(_actLebar.text) ?? 0;

    final susT = cutT - actT;
    final susL = cutL - actL;

    // Update text field secara otomatis
    setState(() {
      _susTebal.text =
      susT == 0 ? '' : susT.toStringAsFixed(susT % 1 == 0 ? 0 : 2);
      _susLebar.text =
      susL == 0 ? '' : susL.toStringAsFixed(susL % 1 == 0 ? 0 : 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final noQc = widget.initial?.noQc ?? '';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0, -1.2),
          end: Alignment(0, -.2),
          colors: [Colors.black12, Colors.transparent],
        ),
      ),
      child: Container(
        padding: EdgeInsets.only(bottom: bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              _SheetHeader(noQc: noQc, noUrut: _noUrutVal),

              const SizedBox(height: 16),
              const _SectionTitle(title: 'Cutting'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cutTebal,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDeco(label: 'Tebal (T)', hint: 'mis. 25'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cutLebar,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDeco(label: 'Lebar (L)', hint: 'mis. 120'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const _SectionTitle(title: 'Actual'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _actTebal,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                      _inputDeco(label: 'Tebal (T)', hint: 'mis. 24.6'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _actLebar,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      decoration:
                      _inputDeco(label: 'Lebar (L)', hint: 'mis. 119.4'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const _SectionTitle(title: 'Susut (Auto Generate)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _susTebal,
                      enabled: false, // tidak bisa diedit manual
                      decoration:
                      _inputDeco(label: 'Tebal (T)', hint: 'otomatis'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _susLebar,
                      enabled: false, // tidak bisa diedit manual
                      decoration:
                      _inputDeco(label: 'Lebar (L)', hint: 'otomatis'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              _ActionButtons(
                onCancel: () => Navigator.pop(context, null),
                onSave: () {
                  if (_noUrutVal == null || _noUrutVal! <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nomor urut belum ditentukan.'),
                      ),
                    );
                    return;
                  }

                  final out = QcSawmillDetail(
                    noQc: noQc,
                    noUrut: _noUrutVal,
                    cuttingTebal: _toD(_cutTebal.text),
                    cuttingLebar: _toD(_cutLebar.text),
                    actualTebal: _toD(_actTebal.text),
                    actualLebar: _toD(_actLebar.text),
                    susutTebal: _toD(_susTebal.text),
                    susutLebar: _toD(_susLebar.text),
                  );

                  Navigator.pop(context, out);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco({required String label, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.grey.shade50,
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
        borderSide: BorderSide(color: Color(0xFF2E6F5D), width: 1.6),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

/// ---------- UI Bits ----------
class _SheetHeader extends StatelessWidget {
  final String noQc;
  final int? noUrut;
  const _SheetHeader({required this.noQc, required this.noUrut});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Detail - $noQc',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF4B322A),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2E6F5D).withOpacity(.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF2E6F5D).withOpacity(.25)),
          ),
          child: Text(
            '#${noUrut ?? '-'}',
            style: const TextStyle(
              color: Color(0xFF2E6F5D),
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: .3,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _ActionButtons({
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF2E6F5D);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: brand,
              side: const BorderSide(color: brand, width: 1.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Batal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: onSave,
            style: FilledButton.styleFrom(
              backgroundColor: brand,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Simpan'),
          ),
        ),
      ],
    );
  }
}
