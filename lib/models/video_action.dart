import 'package:flutter/material.dart';

enum VideoAction {
  play('Play', Icons.play_arrow),
  download('Download', Icons.download),
  share('Share', Icons.share),
  copyLink('Copy Link', Icons.copy);

  const VideoAction(this.label, this.icon);

  final String label;
  final IconData icon;
}
