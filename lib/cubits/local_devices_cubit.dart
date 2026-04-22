import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../services/network_discovery_service.dart';
import 'local_devices_state.dart';

class LocalDevicesCubit extends Cubit<LocalDevicesState> {
  final NetworkDiscoveryService _discoveryService;
  StreamSubscription<List<DiscoveredDevice>>? _subscription;

  LocalDevicesCubit({required NetworkDiscoveryService discoveryService})
    : _discoveryService = discoveryService,
      super(const LocalDevicesInitial());

  Future<void> startDiscovery() async {
    emit(const LocalDevicesDiscovering());
    _subscription = _discoveryService.devicesStream.listen((devices) {
      emit(LocalDevicesDiscovering(devices: devices));
    });
    await _discoveryService.startDiscovery();
  }

  Future<void> stopDiscovery() async {
    await _subscription?.cancel();
    _subscription = null;
    await _discoveryService.stopDiscovery();
  }

  @override
  Future<void> close() async {
    await stopDiscovery();
    return super.close();
  }
}
