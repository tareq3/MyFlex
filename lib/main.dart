import 'package:flutter/material.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'app.dart';

final _updater = ShorebirdUpdater();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _checkForUpdate();
  runApp(const DhakaFlixApp());
}

Future<void> _checkForUpdate() async {
  final status = await _updater.checkForUpdate();

  if (status == UpdateStatus.outdated) {
    await _updater.update();
  }
}
