import 'package:equatable/equatable.dart';

enum DirectoryItemType { folder, video, image, other }

class DirectoryItem extends Equatable {
  final String name;
  final String path;
  final DirectoryItemType type;
  final String? size;
  final DateTime? modifiedDate;

  const DirectoryItem({
    required this.name,
    required this.path,
    required this.type,
    this.size,
    this.modifiedDate,
  });

  bool get isFolder => type == DirectoryItemType.folder;
  bool get isVideo => type == DirectoryItemType.video;
  bool get isImage => type == DirectoryItemType.image;

  String get displayName {
    if (isFolder) return name;
    final lastDot = name.lastIndexOf('.');
    if (lastDot > 0) {
      return name.substring(0, lastDot);
    }
    return name;
  }

  String? extractYear() {
    final yearRegex = RegExp(r'\b(19|20)\d{2}\b');
    final match = yearRegex.firstMatch(name);
    return match?.group(0);
  }

  String extractTitle() {
    var title = displayName;
    title = title.replaceAll(RegExp(r'\b(19|20)\d{2}\b'), '');
    title = title.replaceAll(RegExp(r'[._\-\[\]()]'), ' ');
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    final qualityPatterns = [
      'BluRay',
      'BRRip',
      'HDRip',
      'WEBRip',
      'DVDRip',
      'x264',
      'x265',
      'HEVC',
      '720p',
      '1080p',
      '2160p',
      '4K',
      'AAC',
      'DTS',
      'YIFY',
    ];
    for (final pattern in qualityPatterns) {
      title = title.replaceAll(RegExp(pattern, caseSensitive: false), '');
    }
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    return title;
  }

  @override
  List<Object?> get props => [name, path, type, size, modifiedDate];
}
