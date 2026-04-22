import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BreadcrumbNav extends StatelessWidget {
  final List<String> pathSegments;
  final void Function(int index) onSegmentTap;

  const BreadcrumbNav({
    super.key,
    required this.pathSegments,
    required this.onSegmentTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < pathSegments.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
              ),
            _BreadcrumbItem(
              label: _getSegmentLabel(pathSegments[i]),
              isLast: i == pathSegments.length - 1,
              onTap: () => onSegmentTap(i),
            ),
          ],
        ],
      ),
    );
  }

  String _getSegmentLabel(String path) {
    if (path == '/') return 'Home';
    final parts = path.split('/');
    final segment = parts.last;
    try {
      return Uri.decodeComponent(segment);
    } catch (_) {
      return segment;
    }
  }
}

class _BreadcrumbItem extends StatelessWidget {
  final String label;
  final bool isLast;
  final VoidCallback onTap;

  const _BreadcrumbItem({
    required this.label,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLast ? null : onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: TextStyle(
            color: isLast ? AppTheme.textPrimary : AppTheme.accentColor,
            fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
