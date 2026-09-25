import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  final String initialQuery;
  final void Function(String query) onSearch;
  final void Function(String query)? onGlobalSearch;
  final VoidCallback onClear;
  final bool isGlobalSearchLoading;

  /// Fixed field width; `null` fills the available space.
  final double? width;
  final bool autofocus;

  const SearchBarWidget({
    super.key,
    this.initialQuery = '',
    required this.onSearch,
    this.onGlobalSearch,
    required this.onClear,
    this.isGlobalSearchLoading = false,
    this.width = 300,
    this.autofocus = false,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync external changes; resetting the text while typing breaks the
    // IME composing state on mobile keyboards.
    if (widget.initialQuery != _controller.text) {
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        autofocus: widget.autofocus,
        textInputAction: TextInputAction.search,
        onChanged: widget.onSearch,
        onSubmitted: (query) {
          if (query.isNotEmpty && widget.onGlobalSearch != null) {
            widget.onGlobalSearch!(query);
          }
        },
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_controller.text.isNotEmpty && widget.onGlobalSearch != null)
                IconButton(
                  icon: const Icon(Icons.travel_explore),
                  tooltip: 'Global Server Search',
                  onPressed: () => widget.onGlobalSearch!(_controller.text),
                ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onClear();
                  },
                ),
            ],
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
