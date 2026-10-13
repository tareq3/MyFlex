import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../cubits/directory_cubit.dart';
import '../cubits/directory_state.dart';
import '../cubits/local_devices_cubit.dart';
import '../models/shared_file_offer.dart';
import '../services/deep_link_service.dart';
import '../services/file_share_service.dart';
import '../services/network_discovery_service.dart';
import '../services/share_sender_service.dart';
import '../widgets/device_picker_sheet.dart';
import '../widgets/send_files_sheet.dart';

/// Shares the current directory or downloaded files with nearby devices.
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

  Future<void> sendDownloadedFiles(
    NetworkDiscoveryService discoveryService,
    FileShareService fileShare,
  ) async {
    final files = await fileShare.listDownloadedVideos();
    if (!mounted) return;
    if (files.isEmpty) {
      _showSnackBar('No downloaded movies to send');
      return;
    }

    final selected = await showModalBottomSheet<List<SharedFile>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SendFilesSheet(files: files),
    );
    if (!mounted || selected == null || selected.isEmpty) return;

    final device = await _pickDevice(discoveryService);
    if (!mounted || device == null) return;

    final success = await fileShare.sendOffer(device, selected);
    if (!mounted) return;
    _showSnackBar(
      success
          ? 'Sent to ${device.name}. Keep the app open until it finishes.'
          : 'Failed to reach ${device.name}',
    );
  }

  Future<DiscoveredDevice?> _pickDevice(
    NetworkDiscoveryService discoveryService,
  ) async {
    final devicesCubit = LocalDevicesCubit(discoveryService: discoveryService);
    devicesCubit.startDiscovery();
    final device = await showModalBottomSheet<DiscoveredDevice>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => BlocProvider.value(
        value: devicesCubit,
        child: DevicePickerSheet(
          title: 'Send to Device',
          onDeviceSelected: (device) => Navigator.pop(sheetContext, device),
        ),
      ),
    );
    await devicesCubit.close();
    return device;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
