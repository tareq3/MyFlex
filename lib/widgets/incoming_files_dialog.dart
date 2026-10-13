import 'package:flutter/material.dart';

import '../models/shared_file_offer.dart';
import '../theme/app_theme.dart';

/// Asks whether to accept files another device wants to send.
/// Pops with `true` when accepted.
class IncomingFilesDialog extends StatelessWidget {
  final SharedFileOffer offer;
  final bool replacesCurrentDownload;

  const IncomingFilesDialog({
    super.key,
    required this.offer,
    this.replacesCurrentDownload = false,
  });

  @override
  Widget build(BuildContext context) {
    final count = offer.files.length;
    return AlertDialog(
      title: Text('${offer.senderName} wants to send $count movie(s)'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total size: ${formatBytes(offer.totalSize)}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final file in offer.files)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.movie),
                      title: Text(file.name, overflow: TextOverflow.ellipsis),
                      subtitle: Text(formatBytes(file.size)),
                    ),
                ],
              ),
            ),
            if (replacesCurrentDownload) ...[
              const SizedBox(height: 8),
              const Text(
                'This will stop the download in progress.',
                style: TextStyle(color: AppTheme.accentColor),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Decline'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Accept'),
        ),
      ],
    );
  }
}
