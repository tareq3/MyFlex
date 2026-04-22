import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../cubits/directory_cubit.dart';
import '../cubits/directory_state.dart';
import '../cubits/local_devices_cubit.dart';
import '../cubits/movie_info_cubit.dart';
import '../models/directory_item.dart';
import '../services/deep_link_service.dart';
import '../services/network_discovery_service.dart';
import '../services/share_sender_service.dart';
import '../services/vlc_service.dart';
import '../theme/app_theme.dart';
import '../widgets/breadcrumb_nav.dart';
import '../widgets/device_picker_sheet.dart';
import '../widgets/directory_grid.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/server_selector.dart';
import '../widgets/stats_bar.dart';

class HomeScreen extends StatefulWidget {
  final NetworkDiscoveryService discoveryService;

  const HomeScreen({super.key, required this.discoveryService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final VlcService _vlcService = VlcService();
  final ShareSenderService _shareSender = ShareSenderService();

  @override
  void initState() {
    super.initState();
    context.read<DirectoryCubit>().loadInitialDirectory();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final state = context.read<DirectoryCubit>().state;
        if (state is DirectoryLoaded && state.pathSegments.length > 1) {
          context.read<DirectoryCubit>().navigateBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: BlocBuilder<DirectoryCubit, DirectoryState>(
          builder: (context, state) {
            return switch (state) {
              DirectoryInitial() => const LoadingIndicator(
                message: 'Initializing...',
              ),
              DirectoryLoading() => const LoadingIndicator(
                message: 'Loading directory...',
              ),
              DirectoryLoaded() => _buildLoadedContent(state),
              DirectoryError() => ErrorView(
                message: state.message,
                onRetry: () => context.read<DirectoryCubit>().refresh(),
              ),
            };
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: BlocBuilder<DirectoryCubit, DirectoryState>(
        builder: (context, state) {
          if (state is DirectoryLoaded && state.pathSegments.length > 1) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Go back',
              onPressed: () => context.read<DirectoryCubit>().navigateBack(),
            );
          }
          return const SizedBox.shrink();
        },
      ),
      leadingWidth: 48,
      title: BlocBuilder<DirectoryCubit, DirectoryState>(
        builder: (context, state) {
          if (state is DirectoryLoaded) {
            return BreadcrumbNav(
              pathSegments: state.pathSegments,
              onSegmentTap: (index) {
                context.read<DirectoryCubit>().navigateToSegment(index);
              },
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DHAKA'),
              Text(
                'FLIX',
                style: TextStyle(
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        BlocBuilder<DirectoryCubit, DirectoryState>(
          builder: (context, state) {
            if (state is DirectoryLoaded) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatsBar(
                    folderCount: state.folderCount,
                    videoCount: state.videoCount,
                    imageCount: state.imageCount,
                  ),
                  const SizedBox(width: 16),
                  SearchBarWidget(
                    initialQuery: state.searchQuery,
                    onSearch: (query) {
                      context.read<DirectoryCubit>().search(query);
                    },
                    onClear: () => context.read<DirectoryCubit>().clearSearch(),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
        const SizedBox(width: 8),
        const ServerSelector(),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: 'Share this directory',
          onPressed: _shareAppLink,
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: () => context.read<DirectoryCubit>().refresh(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildLoadedContent(DirectoryLoaded state) {
    return BlocBuilder<MovieInfoCubit, dynamic>(
      builder: (context, movieState) {
        return DirectoryGrid(
          items: state.filteredItems,
          onFolderTap: _handleFolderTap,
          onVideoTap: _handleVideoTap,
        );
      },
    );
  }

  void _handleFolderTap(DirectoryItem item) {
    final path = item.path.endsWith('/') ? item.path : '${item.path}/';
    context.read<DirectoryCubit>().navigateToFolder(path);
  }

  void _handleVideoTap(DirectoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.extractTitle()),
        content: const Text('What would you like to do?'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _copyLink(item);
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Link'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareVideo(item);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadVideo(item);
            },
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _playVideo(item);
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
        ],
      ),
    );
  }

  void _copyLink(DirectoryItem item) {
    final baseUrl = context.read<DirectoryCubit>().currentServer.baseUrl;
    _vlcService.setBaseUrl(baseUrl);
    final url = _vlcService.getVideoUrl(item.path);
    Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
    }
  }

  void _shareAppLink() {
    final cubit = context.read<DirectoryCubit>();
    final state = cubit.state;
    if (state is! DirectoryLoaded) return;

    final devicesCubit = LocalDevicesCubit(
      discoveryService: widget.discoveryService,
    );
    devicesCubit.startDiscovery();

    final deepLink = DeepLinkService.buildDeepLink(
      cubit.currentServer,
      state.path,
    );

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: devicesCubit,
          child: DevicePickerSheet(
            onDeviceSelected: (device) {
              Navigator.pop(sheetContext);
              _sendToDevice(device, cubit, state);
            },
            onOtherApps: () {
              Navigator.pop(sheetContext);
              Share.share(deepLink.toString());
            },
          ),
        );
      },
    ).whenComplete(() => devicesCubit.close());
  }

  Future<void> _sendToDevice(
    DiscoveredDevice device,
    DirectoryCubit cubit,
    DirectoryLoaded state,
  ) async {
    final success = await _shareSender.sendNavigationCommand(
      device.host,
      device.port,
      cubit.currentServer.baseUrl,
      state.path,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Sent to ${device.name}'
              : 'Failed to send to ${device.name}',
        ),
      ),
    );
  }

  void _shareVideo(DirectoryItem item) {
    final baseUrl = context.read<DirectoryCubit>().currentServer.baseUrl;
    _vlcService.setBaseUrl(baseUrl);
    final url = _vlcService.getVideoUrl(item.path);
    Share.share(url);
  }

  Future<void> _playVideo(DirectoryItem item) async {
    final baseUrl = context.read<DirectoryCubit>().currentServer.baseUrl;
    _vlcService.setBaseUrl(baseUrl);
    final success = await _vlcService.playVideo(item.path);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open video player.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }

  Future<void> _downloadVideo(DirectoryItem item) async {
    final baseUrl = context.read<DirectoryCubit>().currentServer.baseUrl;
    _vlcService.setBaseUrl(baseUrl);
    final success = await _vlcService.openInBrowser(item.path);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to open browser.'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
    }
  }
}
