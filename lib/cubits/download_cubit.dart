import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/directory_item.dart';
import '../services/background_download_service.dart';
import '../services/file_download_service.dart';
import 'download_state.dart';

class DownloadCubit extends Cubit<DownloadState> {
  final FileDownloadService _downloadService;
  StreamSubscription<DownloadProgress>? _subscription;

  DownloadCubit({FileDownloadService? downloadService})
    : _downloadService =
          downloadService ??
          (Platform.isAndroid
              ? BackgroundDownloadService()
              : FileDownloadService()),
      super(const DownloadInitial());

  void startDownload({
    required List<DirectoryItem> items,
    required String baseUrl,
  }) async {
    if (items.isEmpty) return;

    // Starting a new batch supersedes the old one in both services.
    await _subscription?.cancel();

    final stream = _downloadService.downloadVideos(
      items: items,
      baseUrl: baseUrl,
    );

    _subscription = stream.listen(
      (progress) async {
        if (progress.isFinished) {
          final savePath = await _downloadService.getSaveDirectoryPath();
          emit(
            DownloadCompleted(
              totalFiles: progress.completedFiles,
              savePath: savePath,
            ),
          );
        } else if (progress.isError) {
          emit(DownloadError(progress.errorMessage ?? 'Download failed'));
        } else {
          final overall =
              (progress.completedFiles + progress.currentFileProgress) /
              progress.totalFiles;
          emit(
            DownloadInProgress(
              items: items,
              completedCount: progress.completedFiles,
              totalCount: progress.totalFiles,
              currentFileName: progress.currentFileName,
              currentFileProgress: progress.currentFileProgress,
              overallProgress: overall.clamp(0.0, 1.0),
            ),
          );
        }
      },
      onError: (err) {
        emit(DownloadError(err.toString()));
      },
    );
  }

  void cancelDownload() {
    _downloadService.cancel();
    _subscription?.cancel();
    emit(const DownloadInitial());
  }

  void dismissCompleted() {
    emit(const DownloadInitial());
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
