import 'dart:io';

import 'package:dhaka_flix/models/vlc_tv.dart';
import 'package:dhaka_flix/services/vlc_remote_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mimics the VLC for Android Remote access endpoints used by the app.
class FakeVlcServer {
  static const code = '123456';
  static const challenge = 'Xy9_challenge';

  /// `sha256('123456Xy9_challenge')`, computed with `shasum -a 256`.
  static const saltedCode =
      'bf991b956cd5f69ddb68a542794fca8c56ae727c15bad51bd7cfeb56a6c48f00';

  /// Ktor's encrypted session values contain `/` and get URI-encoded.
  static const sessionValue = 'a1b2%2Fc3d4';

  late final HttpServer server;
  final playedPaths = <String>[];
  bool inForeground = true;

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(_handle);
  }

  int get port => server.port;

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    final body = await request
        .map((chunk) => String.fromCharCodes(chunk))
        .join();
    switch ((request.method, request.uri.path)) {
      case ('GET', '/secure-url'):
        response.write('https://127.0.0.1:$port');
      case ('POST', '/code'):
        response.write(challenge);
      case ('POST', '/verify-code'):
        if (Uri.splitQueryString(body)['code'] == saltedCode) {
          // Same shape as Ktor's session cookie header.
          response.headers.add(
            HttpHeaders.setCookieHeader,
            'user_session=$sessionValue; Max-Age=31536000; '
            'Expires=Fri, 15 Oct 2027 10:00:00 GMT; Secure; HttpOnly; '
            r'$x-enc=URI_ENCODING; SameSite=Strict',
          );
        }
        response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, '/');
      case ('GET', '/play'):
        final cookie = request.headers.value(HttpHeaders.cookieHeader);
        if (cookie != 'user_session=$sessionValue') {
          response.statusCode = HttpStatus.unauthorized;
        } else if (!inForeground) {
          response.statusCode = HttpStatus.forbidden;
        } else {
          playedPaths.add(request.uri.queryParameters['path']!);
        }
      default:
        response.statusCode = HttpStatus.notFound;
    }
    await response.close();
  }
}

void main() {
  group('VlcRemoteService.parseAddress', () {
    test('bare IP uses the default HTTP port and looks up HTTPS', () {
      expect(VlcRemoteService.parseAddress(' 192.168.1.20 '), (
        host: '192.168.1.20',
        httpPort: 8080,
        httpsPort: null,
      ));
    });

    test('HTTP URL or ip:port sets the HTTP port', () {
      expect(VlcRemoteService.parseAddress('http://192.168.1.20:8081'), (
        host: '192.168.1.20',
        httpPort: 8081,
        httpsPort: null,
      ));
      expect(VlcRemoteService.parseAddress('10.0.0.5:8082')?.httpPort, 8082);
    });

    test('explicit HTTPS URL skips the lookup', () {
      expect(VlcRemoteService.parseAddress('https://10.0.0.5:34209'), (
        host: '10.0.0.5',
        httpPort: 8080,
        httpsPort: 34209,
      ));
    });

    test('empty input is rejected', () {
      expect(VlcRemoteService.parseAddress('  '), isNull);
    });
  });

  test('playPath encodes the video URL so VLC decodes it once', () {
    const url = 'http://172.16.50.7/Movies/My%20Film%20(2020).mkv';
    final path = VlcRemoteService.playPath(url);
    expect(Uri.parse(path).queryParameters, {'id': '0', 'path': url});
  });

  test('saltedCode is lowercase hex sha256 of code + challenge', () {
    expect(
      VlcRemoteService.saltedCode(' 123456 ', FakeVlcServer.challenge),
      FakeVlcServer.saltedCode,
    );
  });

  test('sessionCookie picks user_session from raw Set-Cookie headers', () {
    expect(
      VlcRemoteService.sessionCookie([
        'other=1; Path=/',
        r'user_session=a%2Fb; Secure; $x-enc=URI_ENCODING; SameSite=Strict',
      ]),
      'user_session=a%2Fb',
    );
    expect(VlcRemoteService.sessionCookie(['user_session=; Max-Age=0']), null);
    expect(VlcRemoteService.sessionCookie(null), isNull);
  });

  group('against a fake VLC server', () {
    late FakeVlcServer vlc;
    final service = VlcRemoteService(secure: false);

    setUp(() async {
      vlc = FakeVlcServer();
      await vlc.start();
    });

    tearDown(() => vlc.server.close(force: true));

    VlcTv tvWithCookie(String cookie) => VlcTv(
      host: '127.0.0.1',
      port: VlcTv.defaultPort,
      httpPort: vlc.port,
      cookie: cookie,
    );

    test('securePort reads the HTTPS port from /secure-url', () async {
      expect(await service.securePort('127.0.0.1', vlc.port), vlc.port);
    });

    test('resolves the HTTPS port, pairs with the right code', () async {
      final pairing = await service.startPairing((
        host: '127.0.0.1',
        httpPort: vlc.port,
        httpsPort: null,
      ));
      expect(pairing?.challenge, FakeVlcServer.challenge);
      expect(pairing?.address.httpsPort, vlc.port);
      final tv = await service.verifyCode(pairing!, ' 123456 ');
      expect(tv?.cookie, 'user_session=${FakeVlcServer.sessionValue}');
      expect(tv?.port, vlc.port);
      expect(tv?.httpPort, vlc.port);
    });

    test('code salted with the wrong challenge is rejected', () async {
      final tv = await service.verifyCode((
        address: (host: '127.0.0.1', httpPort: vlc.port, httpsPort: vlc.port),
        challenge: 'stale-challenge',
      ), FakeVlcServer.code);
      expect(tv, isNull);
    });

    test('plays over plain HTTP on the HTTP port', () async {
      // Default (HTTPS pairing) service; the fake server only speaks HTTP.
      final tv = tvWithCookie('user_session=${FakeVlcServer.sessionValue}');
      const url = 'http://server/Movies/A%20B.mkv';
      expect(await VlcRemoteService().play(tv, url), VlcPlayResult.success);
      expect(vlc.playedPaths, [url]);
    });

    test('maps VLC responses to results', () async {
      expect(
        await service.play(tvWithCookie('x=y'), 'http://a/b'),
        VlcPlayResult.unauthorized,
      );
      vlc.inForeground = false;
      expect(
        await service.play(
          tvWithCookie('user_session=${FakeVlcServer.sessionValue}'),
          'http://a/b',
        ),
        VlcPlayResult.notInForeground,
      );
    });

    test('unreachable TV is reported', () async {
      final tv = tvWithCookie('a=b');
      final port = vlc.port;
      await vlc.server.close(force: true);
      expect(await service.play(tv, 'http://a/b'), VlcPlayResult.unreachable);
      expect(await service.requestCode('127.0.0.1', port), isNull);
      expect(await service.securePort('127.0.0.1', port), isNull);
    });
  });

  test('stored TVs without httpPort default to 8080', () {
    final tv = VlcTv.fromJson({'host': 'h', 'port': 8443, 'cookie': 'c=1'});
    expect(tv.httpPort, 8080);
    expect(VlcTv.fromJson(tv.toJson()), tv);
  });
}
