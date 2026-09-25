import 'package:flutter/material.dart';

import '../models/video_action.dart';

/// Dialog that pops with the [VideoAction] the user picked.
class VideoActionsDialog extends StatelessWidget {
  final String title;

  const VideoActionsDialog({super.key, required this.title});

  static const _secondaryActions = [
    VideoAction.copyLink,
    VideoAction.share,
    VideoAction.download,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: const Text('What would you like to do?'),
      actions: [
        for (final action in _secondaryActions)
          TextButton.icon(
            onPressed: () => Navigator.pop(context, action),
            icon: Icon(action.icon),
            label: Text(action.label),
          ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, VideoAction.play),
          icon: Icon(VideoAction.play.icon),
          label: Text(VideoAction.play.label),
        ),
      ],
    );
  }
}
