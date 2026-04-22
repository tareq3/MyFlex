import 'dart:convert';

import 'package:http/http.dart' as http;

class ShareSenderService {
  Future<bool> sendNavigationCommand(
    String host,
    int port,
    String serverUrl,
    String path,
  ) async {
    try {
      final uri = Uri.parse('http://$host:$port/navigate');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'serverUrl': serverUrl, 'path': path}),
          )
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
