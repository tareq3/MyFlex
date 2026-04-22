import 'package:flutter/material.dart';

import '../services/network_discovery_service.dart';

class DeviceListTile extends StatelessWidget {
  final DiscoveredDevice device;
  final VoidCallback onTap;

  const DeviceListTile({super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.devices, size: 32),
      title: Text(device.name),
      subtitle: Text(device.host),
      trailing: const Icon(Icons.send),
      onTap: onTap,
    );
  }
}
