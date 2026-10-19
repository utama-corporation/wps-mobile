import 'package:flutter/material.dart';

/// Bottom sheet konfirmasi penyimpanan perubahan (draft & hapus).
/// Kembalikan `true` jika user menekan "Simpan".
Future<bool> showConfirmSaveSheet(
    BuildContext context, {
      required int draftsCount,
      required int deletedCount,
      Color brandColor = const Color(0xFF2E6F5D),
    }) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final padding = MediaQuery.of(ctx).viewInsets;
      return Padding(
        padding: EdgeInsets.only(bottom: padding.bottom),
        child: _SaveChangesSheetContent(
          draftsCount: draftsCount,
          deletedCount: deletedCount,
          brandColor: brandColor,
        ),
      );
    },
  );
  return result == true;
}

class _SaveChangesSheetContent extends StatelessWidget {
  final int draftsCount;
  final int deletedCount;
  final Color brandColor;

  const _SaveChangesSheetContent({
    required this.draftsCount,
    required this.deletedCount,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // title
          Row(
            children: [
              Icon(Icons.save_outlined, color: brandColor),
              const SizedBox(width: 8),
              const Text(
                'Simpan Perubahan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // content
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (draftsCount > 0)
                  _InfoChipRowPublic(
                    icon: Icons.edit,
                    label: 'Item Baru/Diubah',
                    value: '$draftsCount',
                    color: Colors.amber.shade700,
                  ),
                if (draftsCount > 0 && deletedCount > 0) const SizedBox(height: 8),
                if (deletedCount > 0)
                  _InfoChipRowPublic(
                    icon: Icons.delete_outline,
                    label: 'Hapus',
                    value: '$deletedCount',
                    color: Colors.red.shade700,
                  ),
                if (draftsCount == 0 && deletedCount == 0)
                  Text(
                    'Tidak ada perubahan.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          // actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Simpan'),
                  style: FilledButton.styleFrom(
                    backgroundColor: brandColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChipRowPublic extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChipRowPublic({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
