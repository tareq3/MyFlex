import '../models/directory_item.dart';

/// Picks the best poster image from a directory listing.
class PosterFinder {
  static const _posterKeywords = [
    'poster',
    'cover',
    'thumb',
    'folder',
    'fanart',
  ];

  const PosterFinder._();

  /// Returns the full URL of an image named like a poster, falling back to
  /// the first image, or `null` when there are no images.
  static String? find(List<DirectoryItem> images, String baseUrl) {
    if (images.isEmpty) return null;
    final poster = images.firstWhere((image) {
      final lowerName = image.name.toLowerCase();
      return _posterKeywords.any(lowerName.contains);
    }, orElse: () => images.first);
    return '$baseUrl${_encodePath(poster.path)}';
  }

  static String _encodePath(String path) {
    return path
        .split('/')
        .map((segment) => segment.isEmpty ? '' : Uri.encodeComponent(segment))
        .join('/');
  }
}
