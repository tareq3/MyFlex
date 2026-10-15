import 'package:flutter/material.dart';

import '../models/vlc_tv.dart';
import '../services/vlc_remote_service.dart';
import '../services/vlc_tv_storage.dart';
import '../theme/app_theme.dart';
import '../widgets/vlc_tv_pair_dialog.dart';

/// Plays videos in VLC on a TV through VLC for Android's Remote access.
/// Pairs on first use, then plays in one tap.
mixin HomeTvActions<T extends StatefulWidget> on State<T> {
  final VlcRemoteService _vlcRemote = VlcRemoteService();
  final VlcTvStorage _tvStorage = VlcTvStorage();

  Future<void> playOnTv(String videoUrl) async {
    final tv = await _tvStorage.load() ?? await _pairTv();
    if (tv == null || !mounted) return;
    final result = await _vlcRemote.play(tv, videoUrl);
    if (!mounted) return;
    switch (result) {
      case VlcPlayResult.success:
        _showMessage('Playing on TV');
      case VlcPlayResult.unauthorized:
        await _tvStorage.clear();
        if (!mounted) return;
        final paired = await _pairTv(initialAddress: tv.host);
        if (paired != null && mounted) await playOnTv(videoUrl);
      case VlcPlayResult.notInForeground:
        _showError(
          'Open VLC on the TV, or enable its "video app switch" setting.',
        );
      case VlcPlayResult.unreachable:
        _showError('TV not reachable. Is VLC Remote access on?', retry: true);
      case VlcPlayResult.failed:
        _showError('TV could not play this video.');
    }
  }

  /// Forgets the saved TV and starts pairing again.
  Future<void> changeTv() async {
    final old = await _tvStorage.load();
    if (!mounted) return;
    await _pairTv(initialAddress: old?.host ?? '');
  }

  Future<VlcTv?> _pairTv({String initialAddress = ''}) async {
    final tv = await showDialog<VlcTv>(
      context: context,
      builder: (_) =>
          VlcTvPairDialog(service: _vlcRemote, initialAddress: initialAddress),
    );
    if (tv != null) await _tvStorage.save(tv);
    return tv;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showError(String message, {bool retry = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.accentColor,
        action: retry
            ? SnackBarAction(
                label: 'Change TV',
                textColor: Colors.white,
                onPressed: changeTv,
              )
            : null,
      ),
    );
  }
}
