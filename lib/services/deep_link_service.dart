import '../config/constants.dart';

class DeepLinkData {
  final ServerConfig server;
  final String path;

  const DeepLinkData({required this.server, required this.path});
}

class DeepLinkService {
  static Uri buildDeepLink(ServerConfig server, String path) {
    return Uri(
      scheme: 'dhakaflix',
      host: 'open',
      queryParameters: {'server': server.baseUrl, 'path': path},
    );
  }

  static DeepLinkData? parse(Uri uri) {
    if (uri.scheme != 'dhakaflix' || uri.host != 'open') return null;

    final serverUrl = uri.queryParameters['server'];
    final path = uri.queryParameters['path'];
    if (serverUrl == null || path == null) return null;

    final server = servers.cast<ServerConfig?>().firstWhere(
      (s) => s!.baseUrl == serverUrl,
      orElse: () => null,
    );
    if (server == null) return null;

    return DeepLinkData(server: server, path: path);
  }
}
