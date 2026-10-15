import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../models/vlc_tv.dart';

enum VlcPlayResult {
  success,

  /// Session cookie rejected — the TV needs to be paired again.
  unauthorized,

  /// VLC refuses to start a video while it is in the background unless its
  /// "video app switch" setting is enabled on the TV.
  notInForeground,

  /// TV unreachable, or VLC Remote access is off.
  unreachable,

  /// VLC answered with an unexpected status.
  failed,
}

/// Where VLC listens on a TV. [httpsPort] is null until resolved.
typedef VlcAddress = ({String host, int httpPort, int? httpsPort});

/// A TV showing a code for [challenge]; its `address.httpsPort` is resolved.
typedef VlcPairing = ({VlcAddress address, String challenge});

/// Talks to the Remote access web server built into VLC for Android 3.6+
/// (Settings → Remote access). Pairing uses VLC's one-time code login, which
/// only works over its self-signed HTTPS port.
class VlcRemoteService {
  static const _timeout = Duration(seconds: 10);
  static const _sessionCookieName = 'user_session';

  /// Whether pairing uses HTTPS. Only tests turn it off; VLC requires HTTPS
  /// for login. Playback always uses plain HTTP.
  final bool secure;

  VlcRemoteService({this.secure = true});

  /// Asks VLC (over plain HTTP) which port its HTTPS server is on. It's 8443
  /// only when that port is free on the TV; otherwise VLC picks a random one.
  Future<int?> securePort(String host, int httpPort) async {
    try {
      final response = await _send(
        host,
        httpPort,
        'GET',
        '/secure-url',
        https: false,
      );
      final body = (await utf8.decodeStream(response)).trim();
      if (response.statusCode != HttpStatus.ok) return null;
      final uri = Uri.tryParse(body);
      return uri != null && uri.hasPort ? uri.port : null;
    } catch (_) {
      return null;
    }
  }

  /// Resolves VLC's HTTPS port (unless given) and makes the TV show a code.
  /// Null when VLC can't be reached.
  Future<VlcPairing?> startPairing(VlcAddress address) async {
    final (:host, :httpPort, :httpsPort) = address;
    final port = httpsPort ?? await securePort(host, httpPort);
    if (port == null) return null;
    final challenge = await requestCode(host, port);
    if (challenge == null) return null;
    return (
      address: (host: host, httpPort: httpPort, httpsPort: port),
      challenge: challenge,
    );
  }

  /// Makes the TV display a one-time code (valid ~60 s) and returns the
  /// challenge VLC pairs with it, or null if VLC can't be reached.
  Future<String?> requestCode(String host, int port) async {
    try {
      final response = await _send(host, port, 'POST', '/code', form: '');
      // Used verbatim: the challenge is a random string hashed with the code.
      final challenge = await utf8.decodeStream(response);
      if (response.statusCode != HttpStatus.ok || challenge.isEmpty) {
        return null;
      }
      return challenge;
    } catch (_) {
      return null;
    }
  }

  /// Exchanges the code shown on the TV for a session. Returns null if the
  /// code is wrong/expired or the TV can't be reached.
  Future<VlcTv?> verifyCode(VlcPairing pairing, String code) async {
    final (:host, :httpPort, :httpsPort) = pairing.address;
    final port = httpsPort ?? VlcTv.defaultPort;
    try {
      final response = await _send(
        host,
        port,
        'POST',
        '/verify-code',
        form: 'code=${saltedCode(code, pairing.challenge)}',
      );
      await response.drain<void>();
      final cookie = sessionCookie(
        response.headers[HttpHeaders.setCookieHeader],
      );
      if (cookie == null) return null;
      return VlcTv(host: host, port: port, httpPort: httpPort, cookie: cookie);
    } catch (_) {
      return null;
    }
  }

  /// VLC never receives the code itself: it expects the lowercase hex
  /// SHA-256 of `code + challenge`.
  static String saltedCode(String code, String challenge) =>
      sha256.convert(utf8.encode('${code.trim()}$challenge')).toString();

  /// Tells VLC on the TV to stream [videoUrl]. Unlike login, `/play` accepts
  /// the session cookie on VLC's plain HTTP port, so no TLS is needed.
  Future<VlcPlayResult> play(VlcTv tv, String videoUrl) async {
    try {
      final response = await _send(
        tv.host,
        tv.httpPort,
        'GET',
        playPath(videoUrl),
        cookie: tv.cookie,
        https: false,
      );
      await response.drain<void>();
      return resultForStatus(response.statusCode);
    } catch (_) {
      return VlcPlayResult.unreachable;
    }
  }

  /// Accepts what VLC displays (`http://ip:8080`), a bare IP or `ip:port`
  /// (an HTTP port). An explicit `https://ip:port` skips the `/secure-url`
  /// lookup.
  static VlcAddress? parseAddress(String input) {
    var text = input.trim();
    if (text.isEmpty) return null;
    if (!text.contains('://')) text = 'http://$text';
    final uri = Uri.tryParse(text);
    if (uri == null || uri.host.isEmpty) return null;
    final explicitPort = uri.hasPort ? uri.port : null;
    if (uri.scheme == 'https') {
      return (
        host: uri.host,
        httpPort: VlcTv.defaultHttpPort,
        httpsPort: explicitPort ?? VlcTv.defaultPort,
      );
    }
    return (
      host: uri.host,
      httpPort: explicitPort ?? VlcTv.defaultHttpPort,
      httpsPort: null,
    );
  }

  /// `/play` needs an `id` but ignores it when `path` holds a URI.
  static String playPath(String videoUrl) => Uri(
    path: '/play',
    queryParameters: {'id': '0', 'path': videoUrl},
  ).toString();

  /// Picks `user_session=<value>` out of raw `Set-Cookie` headers. Parsed by
  /// hand because Ktor adds attributes (`$x-enc=…`) that `dart:io`'s strict
  /// cookie parser may reject.
  static String? sessionCookie(List<String>? setCookieHeaders) {
    for (final header in setCookieHeaders ?? const <String>[]) {
      final pair = header.split(';').first.trim();
      if (pair.startsWith('$_sessionCookieName=') &&
          pair.length > _sessionCookieName.length + 1) {
        return pair;
      }
    }
    return null;
  }

  static VlcPlayResult resultForStatus(int status) => switch (status) {
    HttpStatus.ok => VlcPlayResult.success,
    HttpStatus.unauthorized => VlcPlayResult.unauthorized,
    HttpStatus.forbidden => VlcPlayResult.notInForeground,
    _ => VlcPlayResult.failed,
  };

  Future<HttpClientResponse> _send(
    String host,
    int port,
    String method,
    String pathAndQuery, {
    String? form,
    String? cookie,
    bool? https,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5)
      // VLC uses a self-signed certificate; trust it only for the TV itself.
      ..badCertificateCallback = (_, certHost, _) => certHost == host;
    try {
      final uri = Uri.parse(
        '${(https ?? secure) ? 'https' : 'http'}://$host:$port$pathAndQuery',
      );
      final request = await client.openUrl(method, uri).timeout(_timeout);
      request.followRedirects = false;
      if (cookie != null) request.headers.set(HttpHeaders.cookieHeader, cookie);
      if (form != null) {
        request.headers.contentType = ContentType(
          'application',
          'x-www-form-urlencoded',
          charset: 'utf-8',
        );
        request.write(form);
      }
      return await request.close().timeout(_timeout);
    } finally {
      client.close();
    }
  }
}
