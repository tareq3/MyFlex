import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatsBar extends StatelessWidget {
  final int folderCount;
  final int videoCount;
  final int imageCount;

  const StatsBar({
    super.key,
    required this.folderCount,
    required this.videoCount,
    required this.imageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatItem(
          icon: Icons.folder,
          count: folderCount,
          label: 'Folders',
          color: AppTheme.folderColor,
        ),
        const SizedBox(width: 16),
        _StatItem(
          icon: Icons.movie,
          count: videoCount,
          label: 'Videos',
          color: AppTheme.videoColor,
        ),
        if (imageCount > 0) ...[
          const SizedBox(width: 16),
          _StatItem(
            icon: Icons.image,
            count: imageCount,
            label: 'Images',
            color: Colors.green,
          ),
        ],
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$count $label',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
