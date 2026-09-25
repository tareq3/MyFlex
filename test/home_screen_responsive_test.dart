import 'package:dhaka_flix/cubits/directory_cubit.dart';
import 'package:dhaka_flix/cubits/movie_info_cubit.dart';
import 'package:dhaka_flix/models/directory_item.dart';
import 'package:dhaka_flix/screens/home_screen.dart';
import 'package:dhaka_flix/services/directory_service.dart';
import 'package:dhaka_flix/services/network_discovery_service.dart';
import 'package:dhaka_flix/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDirectoryService extends DirectoryService {
  @override
  Future<List<DirectoryItem>> fetchDirectory(
    String path, {
    required String baseUrl,
  }) async {
    return [
      for (var i = 0; i < 6; i++)
        DirectoryItem(
          name: 'A Very Long Folder Name For Testing $i',
          path: '${path}folder$i/',
          type: DirectoryItemType.folder,
        ),
    ];
  }
}

Future<void> _pumpHome(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final cubit = DirectoryCubit(directoryService: _FakeDirectoryService());
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cubit),
        BlocProvider(create: (_) => MovieInfoCubit()),
      ],
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        home: HomeScreen(discoveryService: NetworkDiscoveryService()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  cubit.navigateToFolder('/DHAKA-FLIX-12/English Movies/2024 Releases/');
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('phone layout fits and toggles search', (tester) async {
    await _pumpHome(tester, const Size(360, 740));

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('More options'), findsOneWidget);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    await tester.tap(find.byTooltip('Close search'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop layout shows inline search', (tester) async {
    await _pumpHome(tester, const Size(1400, 900));

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('More options'), findsNothing);
  });
}
