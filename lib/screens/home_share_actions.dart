import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../cubits/directory_cubit.dart';
import '../cubits/directory_state.dart';
import '../cubits/local_devices_cubit.dart';
import '../services/deep_link_service.dart';
import '../services/network_discovery_service.dart';
import '../services/share_sender_service.dart';
import '../widgets/device_picker_sheet.dart';

/// Shares the current directory to a nearby device or another app.
mixin HomeShareActions<T extends StatefulWidget> on State<T> {
  final ShareSenderService _shareSender = ShareSenderService();

  void shareCurrentDirectory(NetworkDiscoveryService discoveryService) {
    final cubit = context.read<DirectoryCubit>();
    final state = cubit.state;
    if (state is! DirectoryLoaded) return;

    final devicesCubit = LocalDevicesCubit(discoveryService: discoveryService);
    devicesCubit.startDiscovery();

    final deepLink = DeepLinkService.buildDeepLink(
      cubit.currentServer,
      state.path,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return BlocProvider.value(
          value: devicesCubit,
          child: DevicePickerSheet(
            onDeviceSelected: (device) {
              Navigator.pop(sheetContext);
              _sendToDevice(device, cubit, state);
            },
            onOtherApps: () {
              Navigator.pop(sheetContext);
              Share.share(deepLink.toString());
            },
          ),
        );
      },
    ).whenComplete(() => devicesCubit.close());
  }

  Future<void> _sendToDevice(
    DiscoveredDevice device,
    DirectoryCubit cubit,
    DirectoryLoaded state,
  ) async {
    final success = await _shareSender.sendNavigationCommand(
      device.host,
      device.port,
      cubit.currentServer.baseUrl,
      state.path,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Sent to ${device.name}'
              : 'Failed to send to ${device.name}',
        ),
      ),
    );
  }
}
