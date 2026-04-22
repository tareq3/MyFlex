import 'dart:async';

import 'package:bonsoir/bonsoir.dart';

class DiscoveredDevice {
  final String name;
  final String host;
  final int port;

  const DiscoveredDevice({
    required this.name,
    required this.host,
    required this.port,
  });
}

class NetworkDiscoveryService {
  static const _serviceType = '_dhakaflix._tcp';

  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  String? _ownName;

  final _devicesController =
      StreamController<List<DiscoveredDevice>>.broadcast();
  final _devices = <String, DiscoveredDevice>{};

  Stream<List<DiscoveredDevice>> get devicesStream => _devicesController.stream;

  Future<void> startAdvertising(String deviceName, int port) async {
    _ownName = deviceName;
    final service = BonsoirService(
      name: deviceName,
      type: _serviceType,
      port: port,
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.initialize();
    await _broadcast!.start();
  }

  Future<void> startDiscovery() async {
    _devices.clear();
    _discovery = BonsoirDiscovery(type: _serviceType);
    await _discovery!.initialize();
    await _discovery!.start();
    _discovery!.eventStream?.listen(_handleDiscoveryEvent);
  }

  void _handleDiscoveryEvent(BonsoirDiscoveryEvent event) {
    if (event is BonsoirDiscoveryServiceFoundEvent) {
      _discovery!.serviceResolver.resolveService(event.service);
    } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
      final service = event.service;
      if (service.name == _ownName) return;
      final host = service.host;
      if (host == null) return;
      _devices[service.name] = DiscoveredDevice(
        name: service.name,
        host: host,
        port: service.port,
      );
      _devicesController.add(_devices.values.toList());
    } else if (event is BonsoirDiscoveryServiceLostEvent) {
      _devices.remove(event.service.name);
      _devicesController.add(_devices.values.toList());
    }
  }

  Future<void> stopDiscovery() async {
    await _discovery?.stop();
    _discovery = null;
    _devices.clear();
  }

  Future<void> stopAdvertising() async {
    await _broadcast?.stop();
    _broadcast = null;
  }

  Future<void> dispose() async {
    await stopDiscovery();
    await stopAdvertising();
    await _devicesController.close();
  }
}
