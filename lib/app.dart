import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/constants.dart';
import 'cubits/directory_cubit.dart';
import 'cubits/movie_info_cubit.dart';
import 'screens/home_screen.dart';
import 'services/deep_link_service.dart';
import 'services/device_info_service.dart';
import 'services/navigation_receiver_service.dart';
import 'services/network_discovery_service.dart';
import 'theme/app_theme.dart';

class DhakaFlixApp extends StatefulWidget {
  const DhakaFlixApp({super.key});

  @override
  State<DhakaFlixApp> createState() => _DhakaFlixAppState();
}

class _DhakaFlixAppState extends State<DhakaFlixApp> {
  final _directoryCubit = DirectoryCubit();
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  final _receiverService = NavigationReceiverService();
  final _discoveryService = NetworkDiscoveryService();
  final _deviceInfoService = DeviceInfoService();
  StreamSubscription<NavigationCommand>? _commandSubscription;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _handleInitialLink();
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleDeepLink);
    _startNetworkServices();
  }

  Future<void> _startNetworkServices() async {
    await _receiverService.start();
    final deviceName = await _deviceInfoService.getDeviceName();
    await _discoveryService.startAdvertising(deviceName, _receiverService.port);
    _commandSubscription = _receiverService.commandStream.listen(
      _handleNavigationCommand,
    );
  }

  void _handleNavigationCommand(NavigationCommand command) {
    final server = servers.cast<ServerConfig?>().firstWhere(
      (s) => s!.baseUrl == command.serverUrl,
      orElse: () => null,
    );
    if (server == null) return;
    _directoryCubit.navigateToDeepLink(server, command.path);
  }

  Future<void> _handleInitialLink() async {
    final uri = await _appLinks.getInitialLink();
    if (uri != null) _handleDeepLink(uri);
  }

  void _handleDeepLink(Uri uri) {
    final data = DeepLinkService.parse(uri);
    if (data != null) {
      _directoryCubit.navigateToDeepLink(data.server, data.path);
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _commandSubscription?.cancel();
    _receiverService.dispose();
    _discoveryService.dispose();
    _directoryCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _directoryCubit),
        BlocProvider(create: (_) => MovieInfoCubit()),
      ],
      child: MaterialApp(
        title: 'Dhaka Flix',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: HomeScreen(discoveryService: _discoveryService),
      ),
    );
  }
}
