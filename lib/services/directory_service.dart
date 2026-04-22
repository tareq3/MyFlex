import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../config/constants.dart';
import '../models/directory_item.dart';

class DirectoryService {
  final http.Client _client;

  DirectoryService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<DirectoryItem>> fetchDirectory(
    String path, {
    required String baseUrl,
  }) async {
    // Properly encode the path like Python's urllib.parse.quote(path, safe='/%')
    final encodedPath = _encodePath(path);
    final url = Uri.parse('$baseUrl$encodedPath');

    final response = await _client.get(
      url,
      headers: {'User-Agent': 'Mozilla/5.0'},
    );

    if (response.statusCode != 200) {
      throw DirectoryFetchException(
        'Failed to fetch directory: ${response.statusCode}',
      );
    }

    return _parseDirectoryListing(response.body, path);
  }

  String _encodePath(String path) {
    // Encode each segment but keep / and % safe
    final segments = path.split('/');
    final encodedSegments = segments.map((segment) {
      if (segment.isEmpty) return '';
      return Uri.encodeComponent(segment);
    }).toList();
    return encodedSegments.join('/');
  }

  List<DirectoryItem> _parseDirectoryListing(String html, String basePath) {
    final document = html_parser.parse(html);
    final items = <DirectoryItem>[];

    final links = document.querySelectorAll('a');

    for (final link in links) {
      final href = link.attributes['href'];

      if (href == null || href.isEmpty) continue;

      // Decode the href for processing
      final hrefDecoded = Uri.decodeComponent(href);

      // Skip parent directory links
      if (hrefDecoded == '..' ||
          hrefDecoded == '../' ||
          hrefDecoded.contains('Parent Directory')) {
        continue;
      }

      // Skip query strings and special links
      if (href.startsWith('?') ||
          href.startsWith('#') ||
          href.startsWith('mailto:') ||
          href.startsWith('http://') ||
          href.startsWith('https://')) {
        continue;
      }

      String name;
      String itemPath;

      // Handle absolute paths - extract relative part
      if (hrefDecoded.startsWith('/') && basePath.isNotEmpty) {
        final baseDecoded = basePath;
        if (hrefDecoded.startsWith(baseDecoded)) {
          final relative = hrefDecoded.substring(baseDecoded.length);
          if (relative.isEmpty) continue;
          name = relative.endsWith('/')
              ? relative.substring(0, relative.length - 1)
              : relative;
          itemPath = hrefDecoded.endsWith('/')
              ? hrefDecoded.substring(0, hrefDecoded.length - 1)
              : hrefDecoded;
        } else {
          continue;
        }
      } else if (!hrefDecoded.startsWith('/')) {
        // Relative path
        name = hrefDecoded.endsWith('/')
            ? hrefDecoded.substring(0, hrefDecoded.length - 1)
            : hrefDecoded;
        itemPath = basePath.endsWith('/')
            ? '$basePath$name'
            : '$basePath/$name';
      } else {
        continue;
      }

      final isFolder = href.endsWith('/');
      final type = _determineType(name, isFolder);

      items.add(DirectoryItem(name: name, path: itemPath, type: type));
    }

    items.sort((a, b) {
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return items;
  }

  DirectoryItemType _determineType(String name, bool isFolder) {
    if (isFolder) return DirectoryItemType.folder;

    final lowerName = name.toLowerCase();

    for (final ext in videoExtensions) {
      if (lowerName.endsWith(ext)) return DirectoryItemType.video;
    }

    for (final ext in imageExtensions) {
      if (lowerName.endsWith(ext)) return DirectoryItemType.image;
    }

    return DirectoryItemType.other;
  }
}

class DirectoryFetchException implements Exception {
  final String message;
  DirectoryFetchException(this.message);

  @override
  String toString() => message;
}
