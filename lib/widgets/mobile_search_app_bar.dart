import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/directory_cubit.dart';
import '../cubits/directory_state.dart';
import 'search_bar_widget.dart';

class MobileSearchAppBar extends StatelessWidget {
  final DirectoryLoaded state;
  final VoidCallback onClose;

  const MobileSearchAppBar({
    super.key,
    required this.state,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DirectoryCubit>();
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Close search',
        onPressed: onClose,
      ),
      titleSpacing: 0,
      title: SearchBarWidget(
        width: null,
        autofocus: true,
        initialQuery: state.searchQuery,
        onSearch: cubit.search,
        onClear: cubit.clearSearch,
      ),
      actions: const [SizedBox(width: 12)],
    );
  }
}
