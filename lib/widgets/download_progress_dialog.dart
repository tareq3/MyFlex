import 'package:flutter/material.dart';

import '../services/file_download_service.dart';
import '../theme/app_theme.dart';

class DownloadProgressDialog extends StatelessWidget {
  final DownloadProgress progress;
  final VoidCallback onCancel;

  const DownloadProgressDialog({
    super.key,
    required this.progress,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final fileIndex = progress.isFinished
        ? progress.totalFiles
        : (progress.completedFiles + 1).clamp(1, progress.totalFiles);
    final overallPercent = progress.isFinished
        ? 1.0
        : ((progress.completedFiles + progress.currentFileProgress) /
                  progress.totalFiles)
              .clamp(0.0, 1.0);

    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      title: Row(
        children: [
          Icon(
            progress.isFinished ? Icons.check_circle : Icons.downloading,
            color: progress.isFinished ? Colors.green : AppTheme.accentColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              progress.isFinished
                  ? 'Download Complete'
                  : 'Downloading Movies...',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (progress.isFinished)
              Text(
                'Successfully downloaded ${progress.totalFiles} movie(s) to your Downloads folder.',
                style: const TextStyle(color: AppTheme.textPrimary),
              )
            else ...[
              Text(
                'File $fileIndex of ${progress.totalFiles}: ${progress.currentFileName}',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress.currentFileProgress,
                backgroundColor: Colors.white12,
                color: AppTheme.accentColor,
              ),
              const SizedBox(height: 8),
              Text(
                'Overall Progress: ${(overallPercent * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (progress.isFinished)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          )
        else
          TextButton(
            onPressed: () {
              onCancel();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel Download'),
          ),
      ],
    );
  }
}
