import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';

class VlcService {
  static const _vlcPaths = {
    'macos': '/Applications/VLC.app/Contents/MacOS/VLC',
    'windows': r'C:\Program Files\VideoLAN\VLC\vlc.exe',
    'linux': '/usr/bin/vlc',
  };

  String _baseUrl = '';

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  String getVideoUrl(String path) {
    final encodedPath = _encodePath(path);
    return '$_baseUrl$encodedPath';
  }

  Future<bool> playVideo(String path) async {
    final videoUrl = getVideoUrl(path);

    if (Platform.isMacOS) {
      return _openVlcDesktop(videoUrl, 'macos');
    } else if (Platform.isWindows) {
      return _openVlcDesktop(videoUrl, 'windows');
    } else if (Platform.isLinux) {
      return _openVlcDesktop(videoUrl, 'linux');
    } else if (Platform.isAndroid) {
      return _playOnAndroid(videoUrl);
    } else if (Platform.isIOS) {
      return _playOnIOS(videoUrl);
    }

    return false;
  }

  Future<bool> openInBrowser(String path) async {
    final videoUrl = getVideoUrl(path);
    final uri = Uri.parse(videoUrl);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      return false;
    }
  }

  String _encodePath(String path) {
    final segments = path.split('/');
    final encodedSegments = segments.map((segment) {
      if (segment.isEmpty) return '';
      return Uri.encodeComponent(segment);
    }).toList();
    return encodedSegments.join('/');
  }

  Future<bool> _openVlcDesktop(String url, String platform) async {
    final vlcPath = _vlcPaths[platform];
    if (vlcPath == null) return false;

    try {
      final vlcFile = File(vlcPath);
      if (!vlcFile.existsSync()) {
        return _fallbackToUrlLauncher(url);
      }

      await Process.start(vlcPath, [url], mode: ProcessStartMode.detached);
      return true;
    } catch (e) {
      return _fallbackToUrlLauncher(url);
    }
  }

  Future<bool> _playOnAndroid(String url) async {
    try {
      final intent = AndroidIntent(
        action: 'action_view',
        data: url,
        type: 'video/*',
      );
      await intent.launch();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _playOnIOS(String url) async {
    final vlcUri = Uri.parse('vlc://${Uri.encodeComponent(url)}');
    try {
      return await launchUrl(vlcUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      return _fallbackToUrlLauncher(url);
    }
  }

  Future<bool> _fallbackToUrlLauncher(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
