import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoService {
  final _deviceInfo = DeviceInfoPlugin();

  Future<String> getDeviceName() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return info.model;
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return info.name;
    } else if (Platform.isMacOS) {
      final info = await _deviceInfo.macOsInfo;
      return info.computerName;
    } else if (Platform.isWindows) {
      final info = await _deviceInfo.windowsInfo;
      return info.computerName;
    } else if (Platform.isLinux) {
      final info = await _deviceInfo.linuxInfo;
      return info.prettyName;
    }
    return 'DhakaFlix Device';
  }
}
