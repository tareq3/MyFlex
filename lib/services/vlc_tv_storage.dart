import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/vlc_tv.dart';

/// Persists the paired VLC TV so "Play on TV" is one click after pairing.
class VlcTvStorage {
  static const _key = 'vlc_tv';

  Future<VlcTv?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return VlcTv.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_key);
      return null;
    }
  }

  Future<void> save(VlcTv tv) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(tv.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
