// lib/features/qc_sawmill/widgets/qc_detail_item_card.dart
import 'package:flutter/material.dart';
import '../model/qc_sawmill_detail.dart';

class QcDetailItemBlendCard extends StatelessWidget {
  final QcSawmillDetail detail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isNew;
  final bool isEdited;

  // ⬇️ Tambahan: nomor tampil 1..N (tidak mengubah data asli)
  final int? displayIndex;

  const QcDetailItemBlendCard({
    super.key,
    required this.detail,
    required this.onEdit,
    required this.onDelete,
    this.isNew = false,
    this.isEdited = false,
    this.displayIndex, // ⬅️ new
  });

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xFF2E6F5D);
    final statusColor = isNew ? Colors.blue : (isEdited ? Colors.orange : brand);

    // Gunakan displayIndex kalau ada, kalau tidak pakai detail.noUrut
    final shownNumber = displayIndex ?? (detail.noUrut ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    _chip('#$shownNumber', statusColor), // ⬅️ di sini pakai shownNumber
                    if (isNew) ...[const SizedBox(width: 6), _chip('Baru', Colors.blue)],
                    if (isEdited) ...[const SizedBox(width: 6), _chip('Diubah', Colors.orange)],
                    const Spacer(),
                    IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit, size: 20), color: statusColor, onPressed: onEdit),
                    IconButton(tooltip: 'Hapus', icon: const Icon(Icons.delete_outline, size: 20), color: Colors.red.shade400, onPressed: onDelete),
                  ],
                ),
                const SizedBox(height: 10),
                _metricRow(title: 'Cutting', color: Colors.purple.shade600, icon: Icons.content_cut, tebal: detail.cuttingTebal, lebar: detail.cuttingLebar),
                const SizedBox(height: 8),
                _metricRow(title: 'Actual',  color: Colors.blue.shade600,   icon: Icons.straighten,  tebal: detail.actualTebal,  lebar: detail.actualLebar),
                const SizedBox(height: 8),
                _metricRow(title: 'Susut',   color: Colors.orange.shade700, icon: Icons.compress,    tebal: detail.susutTebal,   lebar: detail.susutLebar),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- helpers (tidak berubah) ---
  Widget _chip(String text, Color color) { /* ... tetap seperti punyamu ... */
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .2)),
    );
  }
  Widget _metricRow({required String title, required Color color, required IconData icon, required double? tebal, required double? lebar}) { /* ... */
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(width: 28, height: 28, alignment: Alignment.center, decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 10),
        SizedBox(width: 66, child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.black87))),
        Expanded(child: Wrap(spacing: 8, runSpacing: 8, children: [_pill(label: 'T', value: _fmt(tebal)), _pill(label: 'L', value: _fmt(lebar))])),
      ],
    );
  }
  Widget _pill({required String label, required String value}) { /* ... */
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
            child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black87))),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.black87)),
      ]),
    );
  }
  String _fmt(double? v) => v == null ? '-' : v.toStringAsFixed(v % 1 == 0 ? 0 : 2);
}
