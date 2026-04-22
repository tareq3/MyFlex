import 'package:equatable/equatable.dart';

import '../services/network_discovery_service.dart';

sealed class LocalDevicesState extends Equatable {
  const LocalDevicesState();

  @override
  List<Object?> get props => [];
}

class LocalDevicesInitial extends LocalDevicesState {
  const LocalDevicesInitial();
}

class LocalDevicesDiscovering extends LocalDevicesState {
  final List<DiscoveredDevice> devices;

  const LocalDevicesDiscovering({this.devices = const []});

  @override
  List<Object?> get props => [devices];
}
