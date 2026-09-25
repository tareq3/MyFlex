import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/breakpoints.dart';
import '../cubits/directory_cubit.dart';
import '../cubits/movie_info_cubit.dart';
import '../models/directory_item.dart';
import '../services/poster_finder.dart';
import 'folder_card.dart';
import 'video_card.dart';

class DirectoryGrid extends StatelessWidget {
  final String currentPath;
  final List<DirectoryItem> items;
  final void Function(DirectoryItem item) onFolderTap;
  final void Function(DirectoryItem item) onVideoTap;

  const DirectoryGrid({
    super.key,
    required this.currentPath,
    required this.items,
    required this.onFolderTap,
    required this.onVideoTap,
  });

  @override
  Widget build(BuildContext context) {
    final images = items.where((i) => i.isImage).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
        final childAspectRatio = _calculateAspectRatio(constraints.maxWidth);

        // Tighter gaps on phones leave more room for the posters.
        final gap = context.isMobileLayout ? 12.0 : 16.0;
        final displayItems = items
            .where((i) => i.isFolder || i.isVideo)
            .toList();

        return GridView.builder(
          key: PageStorageKey<String>(currentPath),
          padding: EdgeInsets.all(gap),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
          ),
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];
            return _buildItemCard(context, item, images);
          },
        );
      },
    );
  }

  int _calculateCrossAxisCount(double width) {
    if (width > 1400) return 7;
    if (width > 1200) return 6;
    if (width > 1000) return 5;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }

  double _calculateAspectRatio(double width) {
    if (width > 800) return 0.65;
    return 0.7;
  }

  Widget _buildItemCard(
    BuildContext context,
    DirectoryItem item,
    List<DirectoryItem> images,
  ) {
    if (item.isFolder) {
      return FolderCard(item: item, onTap: () => onFolderTap(item));
    }

    if (item.isVideo) {
      final movieInfoCubit = context.read<MovieInfoCubit>();
      final movieInfo = movieInfoCubit.getCachedInfo(item.path);
      final baseUrl = context.read<DirectoryCubit>().currentServer.baseUrl;
      final localPoster = PosterFinder.find(images, baseUrl);

      return VideoCard(
        item: item,
        movieInfo: movieInfo,
        localPosterUrl: localPoster,
        onTap: () => onVideoTap(item),
        onInfoRequest: () => movieInfoCubit.fetchMovieInfo(item),
      );
    }

    return const SizedBox.shrink();
  }
}
