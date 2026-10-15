import 'package:flutter/material.dart';

/// Input fields of [VlcTvPairDialog]: the TV address first, then the
/// one-time code VLC shows on the TV.
class VlcTvPairFields extends StatelessWidget {
  final bool awaitingCode;
  final TextEditingController addressController;
  final TextEditingController codeController;
  final String? error;
  final VoidCallback onSubmit;

  const VlcTvPairFields({
    super.key,
    required this.awaitingCode,
    required this.addressController,
    required this.codeController,
    required this.error,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          awaitingCode
              ? 'Enter the code shown by VLC on your TV.'
              : 'On the TV open VLC → Settings → Remote access, turn it on '
                    'and enter the address it shows.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (awaitingCode)
          TextField(
            key: const ValueKey('vlc-code'),
            controller: codeController,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Code'),
            onSubmitted: (_) => onSubmit(),
          )
        else
          TextField(
            key: const ValueKey('vlc-address'),
            controller: addressController,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'TV address',
              hintText: '192.168.1.20',
            ),
            onSubmitted: (_) => onSubmit(),
          ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
