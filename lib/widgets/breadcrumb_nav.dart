import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'breadcrumb_item.dart';

class BreadcrumbNav extends StatefulWidget {
  final List<String> pathSegments;
  final void Function(int index) onSegmentTap;

  const BreadcrumbNav({
    super.key,
    required this.pathSegments,
    required this.onSegmentTap,
  });

  @override
  State<BreadcrumbNav> createState() => _BreadcrumbNavState();
}

class _BreadcrumbNavState extends State<BreadcrumbNav> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToCurrentSegment();
  }

  @override
  void didUpdateWidget(BreadcrumbNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.pathSegments, widget.pathSegments)) {
      _scrollToCurrentSegment();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Keep the current folder visible when the path is wider than the screen.
  void _scrollToCurrentSegment() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final segments = widget.pathSegments;
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < segments.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: AppTheme.textMuted,
                ),
              ),
            BreadcrumbItem(
              label: _getSegmentLabel(segments[i]),
              isLast: i == segments.length - 1,
              onTap: () => widget.onSegmentTap(i),
            ),
          ],
        ],
      ),
    );
  }

  String _getSegmentLabel(String path) {
    if (path == '/') return 'Home';
    final segment = path.split('/').last;
    try {
      return Uri.decodeComponent(segment);
    } catch (_) {
      return segment;
    }
  }
}
