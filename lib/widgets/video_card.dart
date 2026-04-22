import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_item.dart';
import '../models/movie_info.dart';
import '../theme/app_theme.dart';

class VideoCard extends StatefulWidget {
  final DirectoryItem item;
  final MovieInfo? movieInfo;
  final String? localPosterUrl;
  final VoidCallback onTap;
  final VoidCallback? onInfoRequest;

  const VideoCard({
    super.key,
    required this.item,
    this.movieInfo,
    this.localPosterUrl,
    required this.onTap,
    this.onInfoRequest,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _isHovered = false;
  bool _isFocused = false;

  bool get _isHighlighted => _isHovered || _isFocused;

  @override
  void initState() {
    super.initState();
    widget.onInfoRequest?.call();
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
                    children: [
                      _buildPoster(),
                      _buildGradientOverlay(),
                      _buildContent(),
                      if (_isHighlighted) _buildPlayOverlay(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPoster() {
    // Priority: OMDb poster > local poster > placeholder
    final movieFound = widget.movieInfo?.found == true;
    final omdbPoster = movieFound ? widget.movieInfo?.poster : null;
    final posterUrl = omdbPoster ?? widget.localPosterUrl;

    if (posterUrl != null && posterUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: posterUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppTheme.cardColor,
      child: Center(
        child: Icon(
          Icons.movie,
          size: 48,
          color: AppTheme.videoColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.9),
            ],
            stops: const [0.4, 0.7, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final movieFound = widget.movieInfo?.found == true;
    final displayTitle = movieFound
        ? widget.movieInfo!.title
        : widget.item.extractTitle();

    return Positioned(
      left: 8,
      right: 8,
      bottom: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (movieFound && widget.movieInfo?.year != null) ...[
                Text(
                  widget.movieInfo!.year!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (movieFound && widget.movieInfo?.hasRating == true) ...[
                const Icon(Icons.star, size: 14, color: AppTheme.ratingColor),
                const SizedBox(width: 2),
                Text(
                  widget.movieInfo!.imdbRating!,
                  style: const TextStyle(
                    color: AppTheme.ratingColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: const Center(
          child: Icon(
            Icons.play_circle_fill,
            size: 64,
            color: AppTheme.accentColor,
          ),
        ),
      ),
    );
  }
}
