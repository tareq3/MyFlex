import 'dart:io';

import 'package:dhaka_flix/services/file_download_service.dart';
import 'package:dhaka_flix/services/file_share_service.dart';
import 'package:dhaka_flix/services/navigation_receiver_service.dart';
import 'package:dhaka_flix/services/network_discovery_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

class _TempDirDownloadService extends FileDownloadService {
  final String dir;

  _TempDirDownloadService(this.dir);

  @override
  Future<String> getSaveDirectoryPath() async => dir;
}

void main() {
  late Directory tempDir;
  late FileShareService fileShare;
  late NavigationReceiverService receiver;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_share_test');
    await File('${tempDir.path}/My Movie (2024).mkv').writeAsString('video');
    await File('${tempDir.path}/notes.txt').writeAsString('not a video');

    fileShare = FileShareService(
      downloads: _TempDirDownloadService(tempDir.path),
    );
    receiver = NavigationReceiverService(fileShare: fileShare);
    await receiver.start();
    fileShare.attach(deviceName: 'Sender', port: receiver.port);
  });

  tearDown(() async {
    await receiver.dispose();
    await tempDir.delete(recursive: true);
  });

  test('lists only downloaded videos', () async {
    final files = await fileShare.listDownloadedVideos();
    expect(files.map((f) => f.name), ['My Movie (2024).mkv']);
    expect(files.single.size, 5);
  });

  test('offered files can be downloaded with the offer token', () async {
    final files = await fileShare.listDownloadedVideos();
    final self = DiscoveredDevice(
      name: 'Receiver',
      host: '127.0.0.1',
      port: receiver.port,
    );

    final offerFuture = receiver.offerStream.first;
    expect(await fileShare.sendOffer(self, files), isTrue);
    final offer = await offerFuture;

    expect(offer.senderName, 'Sender');
    expect(offer.totalSize, 5);

    final item = offer.toDownloadItems().single;
    final encoded = item.path
        .split('/')
        .map((s) => s.isEmpty ? '' : Uri.encodeComponent(s))
        .join('/');
    final response = await http.get(Uri.parse('${offer.baseUrl}$encoded'));
    expect(response.statusCode, 200);
    expect(response.body, 'video');

    final wrongToken = await http.get(
      Uri.parse('${offer.baseUrl}/files/bad/My%20Movie%20(2024).mkv'),
    );
    expect(wrongToken.statusCode, 404);
  });
}
