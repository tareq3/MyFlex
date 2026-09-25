import 'package:flutter/material.dart';

import '../models/video_action.dart';

/// Bottom sheet that pops with the [VideoAction] the user picked.
class VideoActionsSheet extends StatelessWidget {
  final String title;

  const VideoActionsSheet({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final action in VideoAction.values)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: Icon(
                action.icon,
                color: action == VideoAction.play ? colorScheme.primary : null,
              ),
              title: Text(action.label),
              onTap: () => Navigator.pop(context, action),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
