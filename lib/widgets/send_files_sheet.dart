import 'package:flutter/material.dart';

import '../models/shared_file_offer.dart';
import '../theme/app_theme.dart';

/// Lets the user pick downloaded files to send; pops with the selection.
class SendFilesSheet extends StatefulWidget {
  final List<SharedFile> files;

  const SendFilesSheet({super.key, required this.files});

  @override
  State<SendFilesSheet> createState() => _SendFilesSheetState();
}

class _SendFilesSheetState extends State<SendFilesSheet> {
  final _selected = <SharedFile>{};

  void _toggle(SharedFile file) {
    setState(() {
      if (!_selected.remove(file)) _selected.add(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalSize = _selected.fold(0, (sum, f) => sum + f.size);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Send Downloaded Movies',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.files.length,
              itemBuilder: (context, index) {
                final file = widget.files[index];
                return CheckboxListTile(
                  value: _selected.contains(file),
                  onChanged: (_) => _toggle(file),
                  activeColor: AppTheme.accentColor,
                  title: Text(
                    file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(formatBytes(file.size)),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.pop(context, _selected.toList()),
                icon: const Icon(Icons.send_to_mobile),
                label: Text(
                  _selected.isEmpty
                      ? 'Select movies to send'
                      : 'Choose device (${_selected.length} • ${formatBytes(totalSize)})',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
