import 'package:flutter/material.dart';

import '../config/breakpoints.dart';
import '../theme/app_theme.dart';

class BreadcrumbItem extends StatelessWidget {
  final String label;
  final bool isLast;
  final VoidCallback onTap;

  const BreadcrumbItem({
    super.key,
    required this.label,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: context.isMobileLayout ? 180 : double.infinity,
      ),
      child: InkWell(
        onTap: isLast ? null : onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isLast ? AppTheme.textPrimary : AppTheme.accentColor,
              fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
