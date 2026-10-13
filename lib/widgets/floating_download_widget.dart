import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/download_cubit.dart';
import '../cubits/download_state.dart';
import '../theme/app_theme.dart';

class FloatingDownloadWidget extends StatelessWidget {
  const FloatingDownloadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DownloadCubit, DownloadState>(
      builder: (context, state) {
        if (state is DownloadInitial) return const SizedBox.shrink();

        final cubit = context.read<DownloadCubit>();

        return Positioned(
          bottom: 20,
          right: 20,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(24),
            color: AppTheme.cardColor,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.accentColor.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: switch (state) {
                DownloadInProgress() => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppTheme.accentColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Downloading (${state.completedCount + 1}/${state.totalCount}) • ${(state.overallProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Cancel downloads',
                      onPressed: cubit.cancelDownload,
                    ),
                  ],
                ),
                DownloadCompleted() => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Downloaded ${state.totalFiles} movie(s)',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: cubit.dismissCompleted,
                    ),
                  ],
                ),
                DownloadError() => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Download Error',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: cubit.dismissCompleted,
                    ),
                  ],
                ),
                DownloadInitial() => const SizedBox.shrink(),
              },
            ),
          ),
        );
      },
    );
  }
}
