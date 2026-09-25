import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../config/breakpoints.dart';
import '../cubits/directory_cubit.dart';
import '../models/directory_item.dart';
import '../models/video_action.dart';
import '../services/vlc_service.dart';
import '../theme/app_theme.dart';
import '../widgets/video_actions_dialog.dart';
import '../widgets/video_actions_sheet.dart';

/// Lets the user pick what to do with a video: a bottom sheet on mobile,
/// a dialog on larger screens.
mixin HomeVideoActions<T extends StatefulWidget> on State<T> {
  final VlcService _vlcService = VlcService();

  Future<void> showVideoActions(DirectoryItem item) async {
    final title = item.extractTitle();
    final action = context.isMobileLayout
        ? await showModalBottomSheet<VideoAction>(
            context: context,
            showDragHandle: true,
            builder: (_) => VideoActionsSheet(title: title),
          )
        : await showDialog<VideoAction>(
            context: context,
            builder: (_) => VideoActionsDialog(title: title),
          );
    if (action == null || !mounted) return;

    _vlcService.setBaseUrl(
      context.read<DirectoryCubit>().currentServer.baseUrl,
    );
    switch (action) {
      case VideoAction.play:
        await _launch(
          _vlcService.playVideo(item.path),
          'Failed to open video player.',
        );
      case VideoAction.download:
        await _launch(
          _vlcService.openInBrowser(item.path),
          'Failed to open browser.',
        );
      case VideoAction.share:
        await Share.share(_vlcService.getVideoUrl(item.path));
      case VideoAction.copyLink:
        await _copyLink(item);
    }
  }

  Future<void> _copyLink(DirectoryItem item) async {
    final url = _vlcService.getVideoUrl(item.path);
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  Future<void> _launch(Future<bool> launch, String errorMessage) async {
    final success = await launch;
    if (success || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: AppTheme.accentColor,
      ),
    );
  }
}
