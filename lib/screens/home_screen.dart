import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/breakpoints.dart';
import '../cubits/directory_cubit.dart';
import '../cubits/directory_state.dart';
import '../models/directory_item.dart';
import '../services/network_discovery_service.dart';
import '../widgets/directory_content.dart';
import '../widgets/error_view.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/loading_indicator.dart';
import 'home_share_actions.dart';
import 'home_video_actions.dart';

class HomeScreen extends StatefulWidget {
  final NetworkDiscoveryService discoveryService;

  const HomeScreen({super.key, required this.discoveryService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with HomeVideoActions, HomeShareActions {
  /// Whether the mobile app bar is showing the search field.
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<DirectoryCubit>().loadInitialDirectory();
  }

  void _setSearching(bool isSearching) {
    if (!isSearching) context.read<DirectoryCubit>().clearSearch();
    setState(() => _isSearching = isSearching);
  }

  void _handleSystemBack() {
    if (_isSearching && context.isMobileLayout) {
      _setSearching(false);
      return;
    }
    final cubit = context.read<DirectoryCubit>();
    final state = cubit.state;
    if (state is DirectoryLoaded && state.pathSegments.length > 1) {
      cubit.navigateBack();
    } else {
      SystemNavigator.pop();
    }
  }

  void _handleFolderTap(DirectoryItem item) {
    if (_isSearching) setState(() => _isSearching = false);
    final path = item.path.endsWith('/') ? item.path : '${item.path}/';
    context.read<DirectoryCubit>().navigateToFolder(path);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleSystemBack();
      },
      child: Scaffold(
        appBar: HomeAppBar(
          isSearching: _isSearching,
          onSearchingChanged: _setSearching,
          onShare: () => shareCurrentDirectory(widget.discoveryService),
        ),
        body: BlocBuilder<DirectoryCubit, DirectoryState>(
          builder: (context, state) {
            return switch (state) {
              DirectoryInitial() => const LoadingIndicator(
                message: 'Initializing...',
              ),
              DirectoryLoading() => const LoadingIndicator(
                message: 'Loading directory...',
              ),
              DirectoryLoaded() => DirectoryContent(
                state: state,
                onFolderTap: _handleFolderTap,
                onVideoTap: showVideoActions,
              ),
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
}
