import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fixture_prediction_model.dart';

class PredictionRepository {
  static const _predictionsKey = 'fixture_predictions_v1';
  static const _weeklyJokerKey = 'weekly_joker_v1';

  Future<FixturePredictionModel?> getPrediction(int fixtureId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_predictionsKey);
    if (raw == null || raw.isEmpty) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final v = map['$fixtureId'];
    if (v is! Map<String, dynamic>) return null;
    return FixturePredictionModel.fromJson(v);
  }

  Future<void> savePrediction(FixturePredictionModel prediction) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_predictionsKey);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(raw) as Map<String, dynamic>);
    map['${prediction.fixtureId}'] = prediction.toJson();
    await prefs.setString(_predictionsKey, jsonEncode(map));
  }

  /// Returns true if joker can be used this week.
  /// Enforces ONE joker per ISO-week (local, per device/user for now).
  Future<bool> canUseJokerThisWeek() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_weeklyJokerKey);
    if (raw == null || raw.isEmpty) return true;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final weekKey = _weekKey(DateTime.now());
    final usedWeek = data['weekKey'] as String?;
    final usedFixtureId = data['fixtureId'] as num?;
    return !(usedWeek == weekKey && usedFixtureId != null);
  }

  /// Stores this fixture as joker for the current week.
  Future<void> setWeeklyJokerFixture(int fixtureId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _weeklyJokerKey,
      jsonEncode({
        'weekKey': _weekKey(DateTime.now()),
        'fixtureId': fixtureId,
        'updatedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<int?> getWeeklyJokerFixtureId() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_weeklyJokerKey);
    if (raw == null || raw.isEmpty) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final weekKey = _weekKey(DateTime.now());
    if ((data['weekKey'] as String?) != weekKey) return null;
    return (data['fixtureId'] as num?)?.toInt();
  }

  String _weekKey(DateTime d) {
    // ISO-ish week key (year-week). Good enough for local placeholder.
    final dayOfYear = int.parse(DateTime(d.year, d.month, d.day)
        .difference(DateTime(d.year, 1, 1))
        .inDays
        .toString()) +
        1;
    final week = ((dayOfYear - d.weekday + 10) / 7).floor();
    return '${d.year}-$week';
  }
}

