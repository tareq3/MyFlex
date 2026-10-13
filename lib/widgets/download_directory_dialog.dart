import 'package:flutter/material.dart';

import '../models/directory_item.dart';
import '../theme/app_theme.dart';

class DownloadDirectoryDialog extends StatelessWidget {
  final String folderName;
  final bool isScanning;
  final List<DirectoryItem> videos;
  final VoidCallback onCopyLinks;
  final VoidCallback onStartDownload;

  const DownloadDirectoryDialog({
    super.key,
    required this.folderName,
    required this.isScanning,
    required this.videos,
    required this.onCopyLinks,
    required this.onStartDownload,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      title: const Row(
        children: [
          Icon(Icons.download, color: AppTheme.accentColor),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Download Movies',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              folderName,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            if (isScanning)
              const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Scanning directory...',
                    style: TextStyle(color: AppTheme.textPrimary),
                  ),
                ],
              )
            else if (videos.isEmpty)
              const Text(
                'No movie files found in this directory.',
                style: TextStyle(color: AppTheme.textSecondary),
              )
            else ...[
              Text(
                'Found ${videos.length} movie${videos.length == 1 ? "" : "s"}:',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.movie,
                            size: 16,
                            color: AppTheme.accentColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              videos[index].name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (!isScanning && videos.isNotEmpty) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy Links'),
            onPressed: () {
              Navigator.of(context).pop();
              onCopyLinks();
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.download, size: 18),
            label: Text('Download In App (${videos.length})'),
            onPressed: () {
              Navigator.of(context).pop();
              onStartDownload();
            },
          ),
        ],
      ],
    );
  }
}
