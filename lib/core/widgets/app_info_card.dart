import 'package:flutter/material.dart';

/// Kartu generik dengan:
/// - header ber-accent + title + sub-info (mis. tanggal)
/// - body berisi beberapa baris info (ikon + label + value)
/// - onTap & onLongPress
class AppInfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;               // contoh: tanggal
  final IconData subtitleIcon;          // ikon kecil di depan subtitle
  final IconData leadingIcon;           // ikon besar di header
  final Color brandColor;               // warna utama header/ikon
  final List<InfoRowData> rows;         // konten body (ikon + label + value)
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry margin;
  final Color? backgroundColor;   // warna dasar kartu (default putih)

  const AppInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleIcon = Icons.calendar_today,
    this.leadingIcon = Icons.description_outlined,
    this.brandColor = const Color(0xFF755330),
    this.rows = const [],
    this.onTap,
    this.onLongPress,
    this.margin = const EdgeInsets.only(bottom: 14),
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: backgroundColor != null ? brandColor : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: brandColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                  border: Border(
                    bottom: BorderSide(color: brandColor, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    // Icon besar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(leadingIcon, color: brandColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: brandColor,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(subtitleIcon,
                                    size: 13, color: Colors.grey[600]),
                                const SizedBox(width: 6),
                                Text(
                                  subtitle!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 24, color: Colors.grey[400]),
                  ],
                ),
              ),

              // Body
              if (rows.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      for (int i = 0; i < rows.length; i++) ...[
                        _InfoRow(
                          icon: rows[i].icon,
                          label: rows[i].label,
                          value: rows[i].value,
                          color: rows[i].color,
                        ),
                        if (i != rows.length - 1) const SizedBox(height: 12),
                      ]
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
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
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
