import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/breakpoints.dart';
import '../cubits/directory_cubit.dart';
import '../cubits/directory_state.dart';
import 'app_logo.dart';
import 'breadcrumb_nav.dart';
import 'mobile_app_bar_actions.dart';
import 'mobile_search_app_bar.dart';
import 'wide_app_bar_actions.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isSearching;
  final ValueChanged<bool> onSearchingChanged;
  final VoidCallback onShare;

  const HomeAppBar({
    super.key,
    required this.isSearching,
    required this.onSearchingChanged,
    required this.onShare,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DirectoryCubit, DirectoryState>(
      builder: (context, state) {
        final loaded = state is DirectoryLoaded ? state : null;
        final isMobile = context.isMobileLayout;
        if (loaded != null && isMobile && isSearching) {
          return MobileSearchAppBar(
            state: loaded,
            onClose: () => onSearchingChanged(false),
          );
        }

        final cubit = context.read<DirectoryCubit>();
        final canGoBack = (loaded?.pathSegments.length ?? 0) > 1;
        return AppBar(
          automaticallyImplyLeading: false,
          leading: canGoBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Go back',
                  onPressed: cubit.navigateBack,
                )
              : null,
          leadingWidth: 48,
          title: loaded == null
              ? const AppLogo()
              : BreadcrumbNav(
                  pathSegments: loaded.pathSegments,
                  onSegmentTap: cubit.navigateToSegment,
                ),
          actions: [
            if (isMobile)
              MobileAppBarActions(
                canSearch: loaded != null,
                onSearch: () => onSearchingChanged(true),
                onShare: onShare,
              )
            else
              WideAppBarActions(state: loaded, onShare: onShare),
          ],
        );
      },
    );
  }
}
