import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shot_models.dart';

class ShotStorageService {
  static const String _statsKey = 'shot_stats';

  Future<ShotStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_statsKey);
    if (statsJson != null) {
      return ShotStats.fromJson(json.decode(statsJson));
    }
    return ShotStats();
  }

  Future<void> saveStats(ShotStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, json.encode(stats.toJson()));
  }
}
