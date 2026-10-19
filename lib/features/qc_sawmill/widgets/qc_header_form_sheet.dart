// lib/features/qc_sawmill/widgets/qc_header_form_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/date_plain_field.dart';
import '../../jenis_kayu/widgets/jenis_kayu_dropdown.dart';
import '../../jenis_kayu/view_model/jenis_kayu_view_model.dart';

import '../../mesin_sawmill/widgets/mesin_sawmill_dropdown.dart';
import '../../mesin_sawmill/view_model/mesin_sawmill_view_model.dart';

import '../model/qc_sawmill_header.dart';
import '../view_model/qc_sawmill_header_view_model.dart';

Future<bool?> showQcHeaderFormSheet(
    BuildContext context, {
      QcSawmillHeader? initial,
    }) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Colors.transparent, // biar rounded & shadow terlihat
    builder: (_) => _QcHeaderFormSheet(initial: initial),
  );
}

class _QcHeaderFormSheet extends StatefulWidget {
  const _QcHeaderFormSheet({required this.initial});
  final QcSawmillHeader? initial;

  @override
  State<_QcHeaderFormSheet> createState() => _QcHeaderFormSheetState();
}

class _QcHeaderFormSheetState extends State<_QcHeaderFormSheet> {
  final _formKey = GlobalKey<FormState>();

  // Controller hanya untuk DISPLAY (full date)
  late final TextEditingController _tglCtrl;

  // Nilai RAW untuk API (selalu yyyy-MM-dd)
  String? _tglYmd;

  late int? _idJenisKayu;   // utk JenisKayuDropdown
  late String? _noMeja;     // utk MesinSawmillDropdown

  bool get isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _tglCtrl = TextEditingController();

    // Prefill
    _tglYmd      = widget.initial?.tgl;
    _idJenisKayu = widget.initial?.idJenisKayu;
    _noMeja      = widget.initial?.meja?.toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _tglCtrl.text = (_tglYmd == null || _tglYmd!.isEmpty)
          ? ''
          : DateFormatter.fullFromYmd(context, _tglYmd!);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tglCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final qcVm = context.read<QcSawmillHeaderViewModel>();
    final idJenis = _idJenisKayu;
    final mejaNo  = _noMeja;

    bool ok = false;

    if (isEdit) {
      ok = await qcVm.updateHeaderByNoQc(
        noQc: widget.initial!.noQc,
        tgl: _tglYmd ?? '',
        idJenisKayu: idJenis,
        meja: mejaNo,
      );
    } else {
      if (idJenis == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jenis kayu wajib dipilih')),
        );
        return;
      }
      ok = await qcVm.createHeader(
        tgl: _tglYmd ?? '',
        idJenisKayu: idJenis,
        meja: mejaNo,
      );
    }

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      final msg = qcVm.error.isEmpty ? 'Operasi gagal' : qcVm.error;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF2E6F5D);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      // layer belakang lembut
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0, -1.1),
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
              // ---------- HEADER ----------
              _SheetHeader(
                title: isEdit ? 'Edit Header' : 'Header Baru',
                subtitle: isEdit? widget.initial!.noQc : 'M.XXXXXX',
                brand: brand,
                isEdit: isEdit,
              ),
              const SizedBox(height: 24),

              // ---------- FIELD: Tanggal ----------
              DatePlainField(
                valueYmd: _tglYmd,
                onChangedYmd: (ymd) {
                  setState(() {
                    _tglYmd = ymd; // RAW utk API
                    _tglCtrl.text = (ymd == null || ymd.isEmpty)
                        ? ''
                        : DateFormatter.fullFromYmd(context, ymd);
                  });
                },
                formatter: (ctx, ymd) => DateFormatter.fullFromYmd(ctx, ymd),
                label: 'Tanggal',
                hint: 'Ketuk untuk memilih tanggal',
                helperText: null,
                validator: (_) =>
                (_tglYmd == null || _tglYmd!.isEmpty) ? 'Tanggal wajib diisi' : null,
                enabled: true,
                firstDate: DateTime(2020),
                lastDate: DateTime(DateTime.now().year + 2),
                initialDate: DateTime.now(),
              ),
              const SizedBox(height: 12),

              // ---------- FIELD: Jenis Kayu ----------
              Consumer<JenisKayuViewModel>(
                builder: (_, vm, __) {
                  if (vm.isLoading && vm.items.isEmpty) {
                    return const SizedBox(
                      height: 56,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final hasSelected = vm.items.any((e) => e.idJenisKayu == _idJenisKayu);
                  final selectedValue = hasSelected ? _idJenisKayu : null;

                  return JenisKayuDropdown(
                    value: selectedValue,
                    onChanged: (val) => setState(() => _idJenisKayu = val),
                    validator: (v) => (v == null) ? 'Jenis kayu wajib' : null,
                    labelText: 'Jenis Kayu',
                    autoload: vm.items.isEmpty,
                    enabled: true,
                  );
                },
              ),
              const SizedBox(height: 12),

              // ---------- FIELD: Meja / Mesin ----------
              Consumer<MesinSawmillViewModel>(
                builder: (_, vm, __) {
                  if (vm.isLoading && vm.items.isEmpty) {
                    return const SizedBox(
                      height: 56,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final hasSelected = vm.items.any((m) => m.noMeja == _noMeja);
                  final selectedValue = hasSelected ? _noMeja : null;

                  return MesinSawmillDropdown(
                    value: selectedValue,
                    onChanged: (val) => setState(() => _noMeja = val),
                    validator: (v) => null,
                    labelText: 'Meja / Mesin',
                    autoload: vm.items.isEmpty,
                    enabled: true,
                  );
                },
              ),

              const SizedBox(height: 20),

              // ---------- ACTIONS ----------
              _ActionButtons(
                brand: brand,
                isBusy: context.watch<QcSawmillHeaderViewModel>().isLoading,
                isEdit: isEdit,
                onCancel: () => Navigator.pop(context, false),
                onSave: _submit,
              ),

              if (context.watch<QcSawmillHeaderViewModel>().isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ==================== UI Bits ====================

class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color brand;
  final bool isEdit;
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.brand,
    required this.isEdit,
  });

  @override
  Widget build(BuildContext context) {
    final txt = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: txt.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4B322A),
                  )),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: txt.bodySmall?.copyWith(
                    color: const Color(0xFF4B322A).withOpacity(.75),
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: brand.withOpacity(.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: brand.withOpacity(.22)),
          ),
          child: Text(
            isEdit ? 'EDIT' : 'BARU',
            style: TextStyle(
              color: brand,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: .4,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Color brand;
  final bool isBusy;
  final bool isEdit;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _ActionButtons({
    required this.brand,
    required this.isBusy,
    required this.isEdit,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isBusy ? null : onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: brand,
              side: BorderSide(color: brand, width: 1.4),
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
            onPressed: isBusy ? null : onSave,
            style: FilledButton.styleFrom(
              backgroundColor: brand,
              disabledBackgroundColor: Colors.grey.shade300,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Header'),
          ),
        ),
      ],
    );
  }
}
