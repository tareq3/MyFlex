import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/directory_item.dart';

class DownloadProgress {
  final int totalFiles;
  final int completedFiles;
  final String currentFileName;
  final double currentFileProgress;
  final bool isFinished;
  final bool isError;
  final String? errorMessage;

  const DownloadProgress({
    required this.totalFiles,
    required this.completedFiles,
    required this.currentFileName,
    required this.currentFileProgress,
    this.isFinished = false,
    this.isError = false,
    this.errorMessage,
  });

  factory DownloadProgress.fromMap(Map<String, dynamic> map) {
    return DownloadProgress(
      totalFiles: map['totalFiles'] as int,
      completedFiles: map['completedFiles'] as int,
      currentFileName: map['currentFileName'] as String,
      currentFileProgress: (map['currentFileProgress'] as num).toDouble(),
      isFinished: map['isFinished'] as bool? ?? false,
      isError: map['isError'] as bool? ?? false,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'totalFiles': totalFiles,
    'completedFiles': completedFiles,
    'currentFileName': currentFileName,
    'currentFileProgress': currentFileProgress,
    'isFinished': isFinished,
    'isError': isError,
    'errorMessage': errorMessage,
  };
}

class FileDownloadService {
  final http.Client _client;
  bool _isCancelled = false;

  FileDownloadService({http.Client? client})
    : _client = client ?? http.Client();

  void cancel() {
    _isCancelled = true;
  }

  Future<String> getSaveDirectoryPath() async {
    if (Platform.isAndroid) {
      final downloadDir = Directory('/storage/emulated/0/Download');
      if (await downloadDir.exists()) {
        return downloadDir.path;
      }
    }
    final appDir =
        await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();
    return appDir.path;
  }

  Stream<DownloadProgress> downloadVideos({
    required List<DirectoryItem> items,
    required String baseUrl,
  }) async* {
    _isCancelled = false;
    final targetDir = await getSaveDirectoryPath();
    int completed = 0;

    for (int i = 0; i < items.length; i++) {
      if (_isCancelled) break;
      final item = items[i];
      final encodedSegments = item.path
          .split('/')
          .map((s) => s.isEmpty ? '' : Uri.encodeComponent(s))
          .join('/');
      final videoUrl = '$baseUrl$encodedSegments';
      final savePath = '$targetDir/${item.name}';

      yield DownloadProgress(
        totalFiles: items.length,
        completedFiles: completed,
        currentFileName: item.name,
        currentFileProgress: 0.0,
      );

      try {
        final request = http.Request('GET', Uri.parse(videoUrl));
        final response = await _client.send(request);
        final file = File(savePath);
        final sink = file.openWrite();
        int received = 0;
        final total = response.contentLength ?? 0;

        await for (final chunk in response.stream) {
          if (_isCancelled) {
            await sink.close();
            if (await file.exists()) {
              await file.delete();
            }
            return;
          }
          received += chunk.length;
          sink.add(chunk);
          final progress = total > 0 ? (received / total) : 0.5;
          yield DownloadProgress(
            totalFiles: items.length,
            completedFiles: completed,
            currentFileName: item.name,
            currentFileProgress: progress,
          );
        }
        await sink.close();
        completed++;
      } catch (e) {
        yield DownloadProgress(
          totalFiles: items.length,
          completedFiles: completed,
          currentFileName: item.name,
          currentFileProgress: 0.0,
          isError: true,
          errorMessage: 'Failed to download ${item.name}: $e',
        );
      }
    }

    yield DownloadProgress(
      totalFiles: items.length,
      completedFiles: completed,
      currentFileName: '',
      currentFileProgress: 1.0,
      isFinished: true,
    );
  }
}
