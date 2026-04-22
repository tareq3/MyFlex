import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/directory_cubit.dart';
import '../models/directory_item.dart';
import '../services/directory_service.dart';
import '../theme/app_theme.dart';

class FolderCard extends StatefulWidget {
  final DirectoryItem item;
  final VoidCallback onTap;

  const FolderCard({super.key, required this.item, required this.onTap});

  @override
  State<FolderCard> createState() => _FolderCardState();
}

class _FolderCardState extends State<FolderCard> {
  bool _isHovered = false;
  bool _isFocused = false;
  String? _thumbnailUrl;
  bool _loadedThumbnail = false;

  bool get _isHighlighted => _isHovered || _isFocused;

  @override
  void initState() {
    super.initState();
    _loadFolderThumbnail();
  }

  Future<void> _loadFolderThumbnail() async {
    if (_loadedThumbnail) return;
    _loadedThumbnail = true;

    try {
      final cubit = context.read<DirectoryCubit>();
      final baseUrl = cubit.currentServer.baseUrl;
      final service = DirectoryService();
      final folderPath = widget.item.path.endsWith('/')
          ? widget.item.path
          : '${widget.item.path}/';
      final items = await service.fetchDirectory(folderPath, baseUrl: baseUrl);

      final images = items.where((i) => i.isImage).toList();
      final videos = items.where((i) => i.isVideo).toList();

      // If folder has images, find a poster
      if (images.isNotEmpty) {
        final posterUrl = _findPoster(images, baseUrl);
        if (mounted && posterUrl != null) {
          setState(() => _thumbnailUrl = posterUrl);
        }
      }
      // If folder has exactly one video and images, use the poster
      else if (videos.length == 1) {
        // Check subfolders for images
        final subfolders = items.where((i) => i.isFolder).toList();
        for (final subfolder in subfolders) {
          try {
            final subPath = subfolder.path.endsWith('/')
                ? subfolder.path
                : '${subfolder.path}/';
            final subItems = await service.fetchDirectory(
              subPath,
              baseUrl: baseUrl,
            );
            final subImages = subItems.where((i) => i.isImage).toList();
            if (subImages.isNotEmpty) {
              final posterUrl = _findPoster(subImages, baseUrl);
              if (mounted && posterUrl != null) {
                setState(() => _thumbnailUrl = posterUrl);
                return;
              }
            }
          } catch (_) {}
        }
      }
    } catch (_) {
      // Ignore errors - just don't show thumbnail
    }
  }

  String? _findPoster(List<DirectoryItem> images, String baseUrl) {
    if (images.isEmpty) return null;

    final posterKeywords = ['poster', 'cover', 'thumb', 'folder', 'fanart'];

    for (final image in images) {
      final lowerName = image.name.toLowerCase();
      for (final keyword in posterKeywords) {
        if (lowerName.contains(keyword)) {
          return '$baseUrl${_encodePath(image.path)}';
        }
      }
    }

    return '$baseUrl${_encodePath(images.first.path)}';
  }

  String _encodePath(String path) {
    final segments = path.split('/');
    final encodedSegments = segments.map((segment) {
      if (segment.isEmpty) return '';
      return Uri.encodeComponent(segment);
    }).toList();
    return encodedSegments.join('/');
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.gameButtonA)) {
      widget.onTap();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) => setState(() => _isFocused = focused),
      onKeyEvent: _handleKeyEvent,
      child: Builder(
        builder: (context) {
          return MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: Matrix4.diagonal3Values(
                  _isHighlighted ? 1.05 : 1.0,
                  _isHighlighted ? 1.05 : 1.0,
                  1.0,
                ),
                transformAlignment: Alignment.center,
                decoration: _isFocused
                    ? BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Card(
                  elevation: _isHighlighted ? 8 : 4,
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [_buildContent(), _buildOverlay()],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (_thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: _thumbnailUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.cardColor,
            AppTheme.cardColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder,
            size: 64,
            color: _isHighlighted
                ? AppTheme.folderColor
                : AppTheme.folderColor.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              widget.item.displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _isHighlighted
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
          ),
        ),
        child: Text(
          widget.item.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _isHighlighted
                ? AppTheme.textPrimary
                : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
