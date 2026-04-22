import 'dart:async';
import 'dart:convert';
import 'dart:io';

class NavigationCommand {
  final String serverUrl;
  final String path;

  const NavigationCommand({required this.serverUrl, required this.path});
}

class NavigationReceiverService {
  HttpServer? _server;
  final _commandController = StreamController<NavigationCommand>.broadcast();

  int get port => _server?.port ?? 0;

  Stream<NavigationCommand> get commandStream => _commandController.stream;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server!.listen(_handleRequest);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.method == 'POST' && request.uri.path == '/navigate') {
      try {
        final body = await utf8.decoder.bind(request).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final serverUrl = json['serverUrl'] as String?;
        final path = json['path'] as String?;
        if (serverUrl != null && path != null) {
          _commandController.add(
            NavigationCommand(serverUrl: serverUrl, path: path),
          );
          request.response.statusCode = HttpStatus.ok;
          request.response.write('OK');
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write('Missing serverUrl or path');
        }
      } catch (_) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write('Invalid request');
      }
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('Not found');
    }
    await request.response.close();
  }

  Future<void> dispose() async {
    await _server?.close();
    await _commandController.close();
  }
}
