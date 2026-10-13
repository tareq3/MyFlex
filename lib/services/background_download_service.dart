import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';

import '../models/directory_item.dart';
import 'file_download_service.dart';

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  FileDownloadService? active;

  service.on('cancel').listen((_) {
    active?.cancel();
    active = null;
    service.stopSelf();
  });

  service.on('downloadBatch').listen((event) async {
    if (event == null) return;
    final int batchId = event['batchId'];
    final String baseUrl = event['baseUrl'] ?? '';
    final items = (event['items'] as List? ?? [])
        .map(
          (m) => DirectoryItem(
            name: m['name'] ?? '',
            path: m['path'] ?? '',
            type: DirectoryItemType.video,
          ),
        )
        .toList();

    // A new batch supersedes the running one.
    active?.cancel();
    final downloader = FileDownloadService();
    active = downloader;

    var lastFile = '';
    var lastPercent = -1;
    await for (final progress in downloader.downloadVideos(
      items: items,
      baseUrl: baseUrl,
    )) {
      if (!identical(active, downloader)) return;

      final percent = (progress.currentFileProgress * 100).floor();
      final fileChanged = progress.currentFileName != lastFile;
      if (!fileChanged &&
          percent == lastPercent &&
          !progress.isFinished &&
          !progress.isError) {
        continue;
      }
      lastFile = progress.currentFileName;
      lastPercent = percent;

      service.invoke('progress', {...progress.toMap(), 'batchId': batchId});

      if (service is AndroidServiceInstance && !progress.isFinished) {
        service.setForegroundNotificationInfo(
          title:
              'Downloading (${progress.completedFiles + 1}/${progress.totalFiles}) • $percent%',
          content: progress.currentFileName,
        );
      }
    }

    if (identical(active, downloader)) {
      active = null;
      service.stopSelf();
    }
  });

  service.invoke('ready');
}

/// Runs downloads in an Android foreground service so they survive the app
/// being backgrounded, and relays progress back to the UI isolate.
class BackgroundDownloadService extends FileDownloadService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        // No custom notificationChannelId: the plugin only creates its own
        // default channel, and a missing channel crashes startForeground.
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
        initialNotificationTitle: 'Dhaka Flix',
        initialNotificationContent: 'Downloading movies in background...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @override
  void cancel() {
    FlutterBackgroundService().invoke('cancel');
  }

  @override
  Stream<DownloadProgress> downloadVideos({
    required List<DirectoryItem> items,
    required String baseUrl,
  }) {
    final service = FlutterBackgroundService();
    final batchId = DateTime.now().microsecondsSinceEpoch;
    final controller = StreamController<DownloadProgress>();

    final subscription = service.on('progress').listen((event) {
      if (event == null || event['batchId'] != batchId) return;
      final progress = DownloadProgress.fromMap(event);
      controller.add(progress);
      if (progress.isFinished) controller.close();
    });
    controller.onCancel = subscription.cancel;

    _startBatch(service, batchId, items, baseUrl).catchError((Object e) {
      controller.addError(e);
      controller.close();
    });

    return controller.stream;
  }

  Future<void> _startBatch(
    FlutterBackgroundService service,
    int batchId,
    List<DirectoryItem> items,
    String baseUrl,
  ) async {
    if (!await service.isRunning()) {
      // Wait until the service isolate has registered its listeners,
      // otherwise the batch event is dropped.
      final ready = service.on('ready').first;
      await service.startService();
      await ready.timeout(const Duration(seconds: 15));
    }
    service.invoke('downloadBatch', {
      'batchId': batchId,
      'baseUrl': baseUrl,
      'items': items.map((v) => {'name': v.name, 'path': v.path}).toList(),
    });
  }
}
