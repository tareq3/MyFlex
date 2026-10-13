import 'package:equatable/equatable.dart';

import '../models/directory_item.dart';

sealed class DownloadState extends Equatable {
  const DownloadState();

  @override
  List<Object?> get props => [];
}

class DownloadInitial extends DownloadState {
  const DownloadInitial();
}

class DownloadInProgress extends DownloadState {
  final List<DirectoryItem> items;
  final int completedCount;
  final int totalCount;
  final String currentFileName;
  final double currentFileProgress;
  final double overallProgress;

  const DownloadInProgress({
    required this.items,
    required this.completedCount,
    required this.totalCount,
    required this.currentFileName,
    required this.currentFileProgress,
    required this.overallProgress,
  });

  @override
  List<Object?> get props => [
    items,
    completedCount,
    totalCount,
    currentFileName,
    currentFileProgress,
    overallProgress,
  ];
}

class DownloadCompleted extends DownloadState {
  final int totalFiles;
  final String savePath;

  const DownloadCompleted({required this.totalFiles, required this.savePath});

  @override
  List<Object?> get props => [totalFiles, savePath];
}

class DownloadError extends DownloadState {
  final String message;

  const DownloadError(this.message);

  @override
  List<Object?> get props => [message];
}
