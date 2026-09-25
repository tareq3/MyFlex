# Dhaka Flix — agent context

Flutter app for browsing the DHAKA-FLIX LAN media servers (plain HTTP directory listings), showing movie posters and playing videos in VLC. Targets Android, iOS, macOS, Windows, Linux (also Android TV via D-pad focus). Dark theme only.

## Commands
- `flutter analyze` — must stay clean for new code (3 pre-existing issues in `movie_service.dart` / `vlc_service.dart`)
- `flutter test` — widget tests in `test/`
- `dart format lib test` — run after every change
- No code generation (no freezed/json_serializable/injectable) — don't run build_runner.
- OTA updates via Shorebird (`shorebird.yaml`, checked in `main.dart`).

## Architecture (flutter_bloc Cubits + plain services, no DI)
```
main.dart            Shorebird update check → DhakaFlixApp
app.dart             Creates DirectoryCubit + MovieInfoCubit, deep links (app_links),
                     starts LAN receiver/advertiser, home: HomeScreen
config/constants.dart  `servers` list (ServerConfig: name, baseUrl, startPath), OMDb key, file extensions
config/breakpoints.dart  Breakpoints.mobile=840, wide=1200; `context.isMobileLayout` / `isWideLayout`
cubits/
  directory_cubit    Current server + path; load/navigate/back/segment/search/refresh
  directory_state    sealed: Initial | Loading(path) | Loaded(path, items, filteredItems, searchQuery, pathSegments) | Error
  movie_info_cubit   OMDb lookups cached per item path (getCachedInfo)
  local_devices_*    LAN device discovery for "share to device"
models/              DirectoryItem (folder/video/image/other, extractTitle/extractYear), MovieInfo, VideoAction enum
services/
  directory_service  GET baseUrl+path, parses HTML index into DirectoryItems
  movie_service      OMDb API
  vlc_service        Builds video URL; plays in VLC (desktop process / Android intent / iOS url) or opens browser
  deep_link_service  dhakaflix://open?server=<baseUrl>&path=<path>
  network_discovery  bonsoir mDNS `_dhakaflix._tcp` advertise + discover
  navigation_receiver  Local HttpServer, POST /navigate {serverUrl, path} → cubit navigates
  share_sender       Sends that POST to another device
  poster_finder      Picks poster image (poster/cover/thumb/folder/fanart, else first image)
screens/
  home_screen        Only screen. PopScope back handling, mobile search toggle state
  home_video_actions / home_share_actions  mixins on State with the action logic
widgets/             One public widget per file (see conventions)
```

## Responsive layout
- `< 840` (mobile): `HomeAppBar` → breadcrumb title + `MobileAppBarActions` (search icon, compact `ServerSelector`, ⋮ menu share/refresh); search opens `MobileSearchAppBar`; video tap → `VideoActionsSheet` bottom sheet; stats shown above grid (`DirectoryContent`).
- `840–1200`: `WideAppBarActions` (inline search, server chip, share, refresh); stats above grid.
- `≥ 1200`: stats also in the app bar. Video tap → `VideoActionsDialog`.
- Grid columns in `DirectoryGrid._calculateCrossAxisCount` (2 → 7).

## Conventions
- Widget files ≤ 100 lines; no private widget classes — extract to their own public file. (Legacy exceptions: `folder_card.dart`, `video_card.dart`.)
- Use current Material 3 APIs (`ColorScheme`, `withValues(alpha:)`, `CardThemeData`); no deprecated styling.
- Check `mounted` / `context.mounted` after every `await` before using `context`.
- Colors come from `AppTheme` constants (`accentColor` red #E50914, etc.).
- Cards support hover (mouse) and focus + select/enter keys (TV remotes) — keep both when editing.
- Tests fake the network by passing a `DirectoryService` subclass to `DirectoryCubit(directoryService: ...)` (see `test/home_screen_responsive_test.dart`).
