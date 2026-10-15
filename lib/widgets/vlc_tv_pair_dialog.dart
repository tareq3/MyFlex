import 'package:flutter/material.dart';

import '../services/vlc_remote_service.dart';
import 'vlc_tv_pair_fields.dart';

/// Pairs with VLC Remote access on a TV. Pops with the paired `VlcTv`, or
/// null when cancelled.
class VlcTvPairDialog extends StatefulWidget {
  final VlcRemoteService service;
  final String initialAddress;

  const VlcTvPairDialog({
    super.key,
    required this.service,
    this.initialAddress = '',
  });

  @override
  State<VlcTvPairDialog> createState() => VlcTvPairDialogState();
}

class VlcTvPairDialogState extends State<VlcTvPairDialog> {
  late final _addressController = TextEditingController(
    text: widget.initialAddress,
  );
  final _codeController = TextEditingController();

  /// Set once the TV is showing a code.
  VlcPairing? _pending;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _addressController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final pending = _pending;
    final address =
        pending?.address ??
        VlcRemoteService.parseAddress(_addressController.text);
    if (address == null) {
      setState(() => _error = 'Enter the TV address, e.g. 192.168.1.20');
      return;
    }
    setState(() => _busy = true);
    final service = widget.service;
    if (pending != null) {
      final tv = await service.verifyCode(pending, _codeController.text);
      if (!mounted) return;
      if (tv != null) return Navigator.pop(context, tv);
    }
    // First step, or the code was wrong/expired: VLC returns the same code
    // while it's valid, otherwise shows a fresh one on the TV.
    final next = await service.startPairing(address);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pending = next ?? pending;
      _error = next == null
          ? 'Could not reach VLC at ${address.host}. Is Remote access on?'
          : pending == null
          ? null
          : 'Wrong or expired code. Check the TV and try again.';
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Pair with VLC on TV'),
    content: VlcTvPairFields(
      awaitingCode: _pending != null,
      addressController: _addressController,
      codeController: _codeController,
      error: _error,
      onSubmit: _submit,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: Text(_pending == null ? 'Get code' : 'Pair'),
      ),
    ],
  );
}
