import 'directory_item.dart';

/// A downloaded file that can be sent to another device.
class SharedFile {
  final String name;
  final int size;

  /// Absolute path on the sending device; never sent over the network.
  final String? localPath;

  const SharedFile({required this.name, required this.size, this.localPath});

  factory SharedFile.fromJson(Map<String, dynamic> json) {
    return SharedFile(name: json['name'] as String, size: json['size'] as int);
  }

  Map<String, dynamic> toJson() => {'name': name, 'size': size};
}

/// Files another device offered to send us. They are pulled from the
/// sender's HTTP server at `http://host:port/files/<token>/<name>`.
class SharedFileOffer {
  final String senderName;
  final String host;
  final int port;
  final String token;
  final List<SharedFile> files;

  const SharedFileOffer({
    required this.senderName,
    required this.host,
    required this.port,
    required this.token,
    required this.files,
  });

  factory SharedFileOffer.fromJson(Map<String, dynamic> json, String host) {
    return SharedFileOffer(
      senderName: json['senderName'] as String,
      host: host,
      port: json['port'] as int,
      token: json['token'] as String,
      files: (json['files'] as List)
          .map((f) => SharedFile.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  String get baseUrl => 'http://$host:$port';

  int get totalSize => files.fold(0, (sum, f) => sum + f.size);

  /// Items for DownloadCubit; their paths are relative to [baseUrl].
  List<DirectoryItem> toDownloadItems() {
    return files
        .map(
          (f) => DirectoryItem(
            name: f.name,
            path: '/files/$token/${f.name}',
            type: DirectoryItemType.video,
          ),
        )
        .toList();
  }
}

String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}
