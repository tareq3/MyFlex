import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/directory_cubit.dart';
import 'server_selector.dart';

class MobileAppBarActions extends StatelessWidget {
  final bool canSearch;
  final VoidCallback onSearch;
  final VoidCallback onShare;
  final VoidCallback? onDownloadAll;

  const MobileAppBarActions({
    super.key,
    required this.canSearch,
    required this.onSearch,
    required this.onShare,
    this.onDownloadAll,
  });

  @override
  Widget build(BuildContext context) {
    final downloadAction = onDownloadAll;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canSearch)
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search',
            onPressed: onSearch,
          ),
        const ServerSelector(compact: true),
        PopupMenuButton<VoidCallback>(
          tooltip: 'More options',
          onSelected: (action) => action(),
          itemBuilder: (context) => [
            if (downloadAction != null)
              _menuItem(
                Icons.file_download,
                'Download all movies',
                downloadAction,
              ),
            _menuItem(Icons.share, 'Share this directory', onShare),
            _menuItem(
              Icons.refresh,
              'Refresh',
              context.read<DirectoryCubit>().refresh,
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<VoidCallback> _menuItem(
    IconData icon,
    String label,
    VoidCallback action,
  ) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [Icon(icon), const SizedBox(width: 12), Text(label)],
      ),
    );
  }
}
