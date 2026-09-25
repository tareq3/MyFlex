import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'stat_item.dart';

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
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatItem(
          icon: Icons.folder,
          count: folderCount,
          label: 'Folders',
          color: AppTheme.folderColor,
        ),
        StatItem(
          icon: Icons.movie,
          count: videoCount,
          label: 'Videos',
          color: AppTheme.videoColor,
        ),
        if (imageCount > 0)
          StatItem(
            icon: Icons.image,
            count: imageCount,
            label: 'Images',
            color: Colors.green,
          ),
      ],
    );
  }
}
