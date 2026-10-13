import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/shared_file_offer.dart';
import 'file_share_service.dart';

class NavigationCommand {
  final String serverUrl;
  final String path;
  final String action;

  const NavigationCommand({
    required this.serverUrl,
    required this.path,
    this.action = 'navigate',
  });
}

/// Local HTTP server other devices talk to:
/// - `POST /navigate` opens a server folder here
/// - `POST /offer` offers downloaded files to this device
/// - `GET /files/<token>/<name>` downloads a file this device offered
class NavigationReceiverService {
  final FileShareService? _fileShare;
  HttpServer? _server;
  final _commandController = StreamController<NavigationCommand>.broadcast();
  final _offerController = StreamController<SharedFileOffer>.broadcast();

  NavigationReceiverService({FileShareService? fileShare})
    : _fileShare = fileShare;

  int get port => _server?.port ?? 0;

  Stream<NavigationCommand> get commandStream => _commandController.stream;

  Stream<SharedFileOffer> get offerStream => _offerController.stream;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server!.listen(_handleRequest);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    final fileShare = _fileShare;
    if (request.method == 'GET' &&
        path.startsWith('/files/') &&
        fileShare != null) {
      await fileShare.serveFile(request);
      return;
    }

    try {
      if (request.method == 'POST' && path == '/navigate') {
        _handleNavigate(await _readJson(request), request.response);
      } else if (request.method == 'POST' && path == '/offer') {
        final host = request.connectionInfo!.remoteAddress.address;
        _offerController.add(
          SharedFileOffer.fromJson(await _readJson(request), host),
        );
        request.response.statusCode = HttpStatus.ok;
        request.response.write('OK');
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Not found');
      }
    } catch (_) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Invalid request');
    }
    await request.response.close();
  }

  Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    return jsonDecode(body) as Map<String, dynamic>;
  }

  void _handleNavigate(Map<String, dynamic> json, HttpResponse response) {
    final serverUrl = json['serverUrl'] as String?;
    final path = json['path'] as String?;
    final action = json['action'] as String? ?? 'navigate';
    if (serverUrl != null && path != null) {
      _commandController.add(
        NavigationCommand(serverUrl: serverUrl, path: path, action: action),
      );
      response.statusCode = HttpStatus.ok;
      response.write('OK');
    } else {
      response.statusCode = HttpStatus.badRequest;
      response.write('Missing serverUrl or path');
    }
  }

  Future<void> dispose() async {
    await _server?.close();
    await _commandController.close();
    await _offerController.close();
  }
}
