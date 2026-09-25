import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/breakpoints.dart';
import '../cubits/directory_state.dart';
import '../cubits/movie_info_cubit.dart';
import '../models/directory_item.dart';
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
        final grid = DirectoryGrid(
          items: state.filteredItems,
          onFolderTap: onFolderTap,
          onVideoTap: onVideoTap,
        );
        // Wide layouts show the stats in the app bar instead.
        if (context.isWideLayout) return grid;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
      },
    );
  }
}
