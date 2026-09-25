import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/constants.dart';
import '../cubits/directory_cubit.dart';
import '../theme/app_theme.dart';

class ServerSelector extends StatelessWidget {
  /// Shows only an icon instead of the server name chip.
  final bool compact;

  const ServerSelector({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<DirectoryCubit>();
    final currentServer = cubit.currentServer;

    return PopupMenuButton<ServerConfig>(
      tooltip: compact ? 'Server: ${currentServer.name}' : 'Select Server',
      offset: const Offset(0, 40),
      icon: compact ? const Icon(Icons.dns) : null,
      child: compact
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.dns, size: 16, color: AppTheme.accentColor),
                  const SizedBox(width: 6),
                  Text(
                    currentServer.name,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
      itemBuilder: (context) {
        return servers.map((server) {
          final isSelected = server.baseUrl == currentServer.baseUrl;
          return PopupMenuItem<ServerConfig>(
            value: server,
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  size: 18,
                  color: isSelected ? AppTheme.accentColor : AppTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Text(server.name),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (server) {
        context.read<DirectoryCubit>().switchServer(server);
      },
    );
  }
}
