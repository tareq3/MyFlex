import 'package:dhaka_flix/models/vlc_tv.dart';
import 'package:dhaka_flix/services/vlc_remote_service.dart';
import 'package:dhaka_flix/widgets/vlc_tv_pair_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeVlcRemoteService extends VlcRemoteService {
  final requested = <(String, int)>[];
  final verified = <(String, String)>[];

  /// Like a TV where 8443 is taken, so VLC picked a random HTTPS port.
  @override
  Future<int?> securePort(String host, int httpPort) async =>
      host == 'offline' ? null : 34209;

  @override
  Future<String?> requestCode(String host, int port) async {
    requested.add((host, port));
    return host == 'offline' ? null : 'challenge-${requested.length}';
  }

  @override
  Future<VlcTv?> verifyCode(VlcPairing pairing, String code) async {
    verified.add((code, pairing.challenge));
    final (:host, :httpPort, :httpsPort) = pairing.address;
    return code == '1234'
        ? VlcTv(host: host, port: httpsPort!, httpPort: httpPort, cookie: 'c=1')
        : null;
  }
}

void main() {
  late FakeVlcRemoteService service;
  VlcTv? result;

  Future<void> openDialog(WidgetTester tester) async {
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<VlcTv>(
                context: context,
                builder: (_) => VlcTvPairDialog(service: service),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() => service = FakeVlcRemoteService());

  testWidgets('pairs after entering address and code', (tester) async {
    await openDialog(tester);
    await tester.enterText(
      find.byKey(const ValueKey('vlc-address')),
      'http://10.0.0.9:8081',
    );
    await tester.tap(find.text('Get code'));
    await tester.pumpAndSettle();
    expect(service.requested, [('10.0.0.9', 34209)]);

    await tester.enterText(find.byKey(const ValueKey('vlc-code')), '0000');
    await tester.tap(find.text('Pair'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Wrong or expired code'), findsOneWidget);
    // A failed attempt refreshes the challenge for the next try.
    expect(service.requested, hasLength(2));

    await tester.enterText(find.byKey(const ValueKey('vlc-code')), '1234');
    await tester.tap(find.text('Pair'));
    await tester.pumpAndSettle();
    expect(service.verified, [
      ('0000', 'challenge-1'),
      ('1234', 'challenge-2'),
    ]);
    expect(find.byType(VlcTvPairDialog), findsNothing);
    expect(
      result,
      const VlcTv(host: '10.0.0.9', port: 34209, httpPort: 8081, cookie: 'c=1'),
    );
  });

  testWidgets('shows an error when VLC is unreachable', (tester) async {
    await openDialog(tester);
    await tester.enterText(
      find.byKey(const ValueKey('vlc-address')),
      'offline',
    );
    await tester.tap(find.text('Get code'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not reach VLC'), findsOneWidget);
    expect(find.byKey(const ValueKey('vlc-address')), findsOneWidget);
  });
}
