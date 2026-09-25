import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/breakpoints.dart';
import '../cubits/directory_cubit.dart';
import '../cubits/directory_state.dart';
import 'search_bar_widget.dart';
import 'server_selector.dart';
import 'stats_bar.dart';

class WideAppBarActions extends StatelessWidget {
  final DirectoryLoaded? state;
  final VoidCallback onShare;

  const WideAppBarActions({
    super.key,
    required this.state,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DirectoryCubit>();
    final loaded = state;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loaded != null) ...[
          if (context.isWideLayout) ...[
            StatsBar(
              folderCount: loaded.folderCount,
              videoCount: loaded.videoCount,
              imageCount: loaded.imageCount,
            ),
            const SizedBox(width: 16),
          ],
          SearchBarWidget(
            initialQuery: loaded.searchQuery,
            onSearch: cubit.search,
            onGlobalSearch: cubit.startGlobalSearch,
            onClear: cubit.clearSearch,
            isGlobalSearchLoading: loaded.isGlobalSearchLoading,
          ),
        ],
        const SizedBox(width: 8),
        const ServerSelector(),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: 'Share this directory',
          onPressed: onShare,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: cubit.refresh,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
