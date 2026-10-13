import 'package:dhaka_flix/cubits/directory_cubit.dart';
import 'package:dhaka_flix/cubits/download_cubit.dart';
import 'package:dhaka_flix/cubits/movie_info_cubit.dart';
import 'package:dhaka_flix/models/directory_item.dart';
import 'package:dhaka_flix/screens/home_screen.dart';
import 'package:dhaka_flix/services/directory_service.dart';
import 'package:dhaka_flix/services/file_share_service.dart';
import 'package:dhaka_flix/services/network_discovery_service.dart';
import 'package:dhaka_flix/theme/app_theme.dart';
import 'package:dhaka_flix/widgets/download_directory_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeDirectoryServiceWithVideos extends DirectoryService {
  @override
  Future<List<DirectoryItem>> fetchDirectory(
    String path, {
    required String baseUrl,
  }) async {
    if (path == '/DHAKA-FLIX-12/Movies/') {
      return [
        const DirectoryItem(
          name: 'Movie 1.mp4',
          path: '/DHAKA-FLIX-12/Movies/Movie 1.mp4',
          type: DirectoryItemType.video,
        ),
        const DirectoryItem(
          name: 'Movie 2.mkv',
          path: '/DHAKA-FLIX-12/Movies/Movie 2.mkv',
          type: DirectoryItemType.video,
        ),
      ];
    }
    return [];
  }
}

void main() {
  test(
    'fetchAllVideosInDirectory returns all video files in directory',
    () async {
      final service = _FakeDirectoryServiceWithVideos();
      final videos = await service.fetchAllVideosInDirectory(
        startPath: '/DHAKA-FLIX-12/Movies/',
        baseUrl: 'http://192.168.1.10:8080',
      );

      expect(videos.length, equals(2));
      expect(videos[0].name, equals('Movie 1.mp4'));
      expect(videos[1].name, equals('Movie 2.mkv'));
    },
  );

  testWidgets(
    'Download all movies button opens DownloadDirectoryDialog with options',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = DirectoryCubit(
        directoryService: _FakeDirectoryServiceWithVideos(),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider(create: (_) => MovieInfoCubit()),
            BlocProvider(create: (_) => DownloadCubit()),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: HomeScreen(
              discoveryService: NetworkDiscoveryService(),
              fileShareService: FileShareService(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      cubit.navigateToFolder('/DHAKA-FLIX-12/Movies/');
      await tester.pumpAndSettle();

      final downloadButton = find.byTooltip(
        'Download all movies from directory',
      );
      expect(downloadButton, findsOneWidget);

      await tester.tap(downloadButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.byType(DownloadDirectoryDialog), findsOneWidget);
      expect(find.text('Download Movies'), findsOneWidget);
      expect(find.text('Copy Links'), findsOneWidget);
      expect(find.text('Download In App (2)'), findsOneWidget);
    },
  );
}
