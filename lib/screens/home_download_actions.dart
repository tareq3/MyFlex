import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../cubits/directory_cubit.dart';
import '../cubits/directory_state.dart';
import '../cubits/download_cubit.dart';
import '../models/directory_item.dart';
import '../services/vlc_service.dart';
import '../theme/app_theme.dart';
import '../widgets/download_directory_dialog.dart';

mixin HomeDownloadActions<T extends StatefulWidget> on State<T> {
  final VlcService _downloadVlcService = VlcService();

  Future<void> downloadAllMoviesInCurrentDirectory() async {
    final cubit = context.read<DirectoryCubit>();
    final state = cubit.state;
    if (state is! DirectoryLoaded) return;

    final baseUrl = cubit.currentServer.baseUrl;
    final startPath = state.path;
    final service = cubit.directoryService;

    _downloadVlcService.setBaseUrl(baseUrl);

    bool isScanning = true;
    bool scanStarted = false;
    List<DirectoryItem> videos = [];

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!scanStarted) {
              scanStarted = true;
              service
                  .fetchAllVideosInDirectory(
                    startPath: startPath,
                    baseUrl: baseUrl,
                  )
                  .then((result) {
                    if (dialogContext.mounted) {
                      setDialogState(() {
                        videos = result;
                        isScanning = false;
                      });
                    }
                  });
            }

            return DownloadDirectoryDialog(
              folderName: startPath,
              isScanning: isScanning,
              videos: videos,
              onCopyLinks: () => _copyAllLinks(videos, baseUrl),
              onStartDownload: () => _startInAppDownload(videos, baseUrl),
            );
          },
        );
      },
    );
  }

  Future<void> _copyAllLinks(List<DirectoryItem> videos, String baseUrl) async {
    if (videos.isEmpty || !mounted) return;

    final links = videos
        .map((video) {
          final encodedSegments = video.path
              .split('/')
              .map((s) => s.isEmpty ? '' : Uri.encodeComponent(s))
              .join('/');
          return '$baseUrl$encodedSegments';
        })
        .join('\n');

    await Clipboard.setData(ClipboardData(text: links));
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied ${videos.length} download link(s) to clipboard! Paste into 1DM/ADM/IDM to download.',
        ),
        backgroundColor: AppTheme.cardColor,
      ),
    );
  }

  Future<void> _startInAppDownload(
    List<DirectoryItem> videos,
    String baseUrl,
  ) async {
    if (videos.isEmpty || !mounted) return;

    // Android 13+ hides the foreground-service progress notification
    // unless the user grants this; downloading works either way.
    if (Platform.isAndroid) {
      await Permission.notification.request();
      if (!mounted) return;
    }

    context.read<DownloadCubit>().startDownload(
      items: videos,
      baseUrl: baseUrl,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Started downloading ${videos.length} movie(s). Will continue even in background!',
        ),
        backgroundColor: AppTheme.cardColor,
      ),
    );
  }
}
