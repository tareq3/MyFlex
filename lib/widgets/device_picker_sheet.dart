import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/local_devices_cubit.dart';
import '../cubits/local_devices_state.dart';
import '../services/network_discovery_service.dart';
import 'device_list_empty_state.dart';
import 'device_list_tile.dart';

class DevicePickerSheet extends StatelessWidget {
  final void Function(DiscoveredDevice device) onDeviceSelected;
  final VoidCallback onOtherApps;

  const DevicePickerSheet({
    super.key,
    required this.onDeviceSelected,
    required this.onOtherApps,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Share to Device',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Flexible(
            child: BlocBuilder<LocalDevicesCubit, LocalDevicesState>(
              builder: (context, state) {
                if (state is LocalDevicesDiscovering &&
                    state.devices.isNotEmpty) {
                  return _buildDeviceList(state.devices);
                }
                return const DeviceListEmptyState();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOtherApps,
                icon: const Icon(Icons.share),
                label: const Text('Other apps...'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(List<DiscoveredDevice> devices) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: devices.length,
      itemBuilder: (context, index) {
        return DeviceListTile(
          device: devices[index],
          onTap: () => onDeviceSelected(devices[index]),
        );
      },
    );
  }
}
