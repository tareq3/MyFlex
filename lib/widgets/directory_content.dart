import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/breakpoints.dart';
import '../cubits/directory_cubit.dart';
import '../cubits/directory_state.dart';
import '../cubits/movie_info_cubit.dart';
import '../models/directory_item.dart';
import '../theme/app_theme.dart';
import 'directory_grid.dart';
import 'stats_bar.dart';

class DirectoryContent extends StatelessWidget {
  final DirectoryLoaded state;
  final void Function(DirectoryItem item) onFolderTap;
  final void Function(DirectoryItem item) onVideoTap;

  const DirectoryContent({
    super.key,
    required this.state,
    required this.onFolderTap,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MovieInfoCubit, dynamic>(
      builder: (context, movieState) {
        Widget buildBody() {
          final grid = DirectoryGrid(
            currentPath: state.isGlobalSearch ? 'global_${state.searchQuery}' : state.path,
            items: state.filteredItems,
            onFolderTap: onFolderTap,
            onVideoTap: onVideoTap,
          );

          if (!state.isGlobalSearch && context.isWideLayout) return grid;

          final cubit = context.read<DirectoryCubit>();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.isGlobalSearch)
                Container(
                  color: AppTheme.cardColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      if (state.isGlobalSearchLoading) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          state.isGlobalSearchLoading
                              ? 'Global search: scanned ${state.scannedFoldersCount} folders, found ${state.filteredItems.length} matches...'
                              : 'Global search completed: ${state.filteredItems.length} matches found',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (state.isGlobalSearchLoading)
                        TextButton.icon(
                          icon: const Icon(Icons.cancel, size: 18),
                          label: const Text('Stop'),
                          onPressed: cubit.cancelGlobalSearch,
                        ),
                    ],
                  ),
                )
              else if (!context.isWideLayout)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: StatsBar(
                    folderCount: state.folderCount,
                    videoCount: state.videoCount,
                    imageCount: state.imageCount,
                  ),
                ),
              Expanded(child: grid),
            ],
          );
        }

        return buildBody();
      },
    );
  }
}
