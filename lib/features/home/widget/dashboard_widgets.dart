import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Token visual bersama untuk komponen dashboard.
const kBrand = Color(0xFF2E6F5D);
const kHairline = Color(0xFFE7E1D8);
const kCanvas = Color(0xFFF4F1EC);

/// Petak statistik datar (tanpa bayangan) untuk baris ringkasan.
class DashboardStatTile extends StatelessWidget {
  final String value;
  final String label;

  const DashboardStatTile({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: kBrand,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.25,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder shimmer dengan bentuk yang sama seperti [DashboardStatTile].
class DashboardStatShimmer extends StatelessWidget {
  const DashboardStatShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kHairline),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 42, height: 20, color: Colors.white),
            const SizedBox(height: 9),
            Container(width: double.infinity, height: 11, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

/// Kartu modul datar untuk grid menu utama.
class DashboardModuleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool allowed;
  final VoidCallback onTap;

  const DashboardModuleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.allowed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kHairline),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: allowed ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kBrand.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, size: 22, color: kBrand),
                    ),
                    const Spacer(),
                    if (!allowed)
                      Icon(Icons.lock_outline,
                          size: 14, color: Colors.grey.shade400),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (allowed) return tile;
    return Tooltip(
      message: 'Anda tidak punya akses',
      triggerMode: TooltipTriggerMode.longPress,
      child: Opacity(opacity: 0.45, child: tile),
    );
  }
}
