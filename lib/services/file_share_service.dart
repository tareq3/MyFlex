import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../config/constants.dart';
import '../models/shared_file_offer.dart';
import 'file_download_service.dart';
import 'network_discovery_service.dart';

/// Sends downloaded videos to other devices running the app.
///
/// The sender only announces an offer; the receiver pulls the files from
/// the sender's [NavigationReceiverService] HTTP server. Each offer gets a
/// random token, and only files in a known offer are ever served.
class FileShareService {
  final FileDownloadService _downloads;
  final _offers = <String, Map<String, String>>{};
  final _random = Random.secure();

  String _deviceName = 'Unknown device';
  int _localPort = 0;

  FileShareService({FileDownloadService? downloads})
    : _downloads = downloads ?? FileDownloadService();

  /// Called once the local HTTP server is up.
  void attach({required String deviceName, required int port}) {
    _deviceName = deviceName;
    _localPort = port;
  }

  Future<List<SharedFile>> listDownloadedVideos() async {
    final dir = Directory(await _downloads.getSaveDirectoryPath());
    if (!await dir.exists()) return [];

    final files = <SharedFile>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      final lower = name.toLowerCase();
      if (!videoExtensions.any(lower.endsWith)) continue;
      final size = await entity.length();
      if (size == 0) continue;
      files.add(SharedFile(name: name, size: size, localPath: entity.path));
    }
    files.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return files;
  }

  Future<bool> sendOffer(
    DiscoveredDevice device,
    List<SharedFile> files,
  ) async {
    if (files.isEmpty || _localPort == 0) return false;

    final token = _newToken();
    _offers[token] = {for (final f in files) f.name: f.localPath!};

    try {
      final response = await http
          .post(
            Uri.parse('http://${device.host}:${device.port}/offer'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'senderName': _deviceName,
              'port': _localPort,
              'token': token,
              'files': files.map((f) => f.toJson()).toList(),
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) return true;
    } catch (_) {}
    _offers.remove(token);
    return false;
  }

  /// Serves `GET /files/<token>/<name>` and closes the response.
  Future<void> serveFile(HttpRequest request) async {
    final response = request.response;
    final segments = request.uri.pathSegments;
    final offer = segments.length == 3 ? _offers[segments[1]] : null;
    final localPath = offer == null ? null : offer[segments[2]];
    final file = localPath == null ? null : File(localPath);

    if (file == null || !await file.exists()) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    try {
      response.headers.contentType = ContentType.binary;
      response.contentLength = await file.length();
      await response.addStream(file.openRead());
      await response.close();
    } catch (_) {
      // Receiver cancelled or disconnected mid-transfer.
    }
  }

  String _newToken() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
