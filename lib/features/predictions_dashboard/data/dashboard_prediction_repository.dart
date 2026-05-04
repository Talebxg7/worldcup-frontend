import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../models/dashboard_prediction_model.dart';

/// Local persistence for dashboard rows. Firestore path (later):
/// `users/{userId}/predictions/{fixtureId}` with the same field names as [DashboardPredictionModel.toFirestoreMap].
class DashboardPredictionRepository {
  static const _prefsKey = 'dashboard_predictions_v1';

  Future<List<DashboardPredictionModel>> loadAll() async {
    try {
      final res = await ApiClient.instance.get('/predictions/mine');
      final list = res.data as List;
      final parsed = list.map((e) => DashboardPredictionModel.fromJson(e as Map<String, dynamic>)).toList();
      
      // Update local cache
      final prefs = await SharedPreferences.getInstance();
      final map = {for (var e in parsed) e.fixtureId: e.toJson()};
      await prefs.setString(_prefsKey, jsonEncode(map));
      
      return parsed;
    } catch (e) {
      // Fallback to local cache
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null || raw.isEmpty) return [];
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.values
          .whereType<Map<String, dynamic>>()
          .map(DashboardPredictionModel.fromJson)
          .toList();
    }
  }

  Future<void> upsert(DashboardPredictionModel row) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    final map = raw == null || raw.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    map[row.fixtureId] = row.toJson();
    await prefs.setString(_prefsKey, jsonEncode(map));
  }

  /// Placeholder for `users/{userId}/predictions/{fixtureId}` sync.
  Future<void> syncToFirestorePlaceholder({
    required String userId,
    required DashboardPredictionModel row,
  }) async {
    // TODO: FirebaseFirestore.instance
    //   .collection('users').doc(userId)
    //   .collection('predictions').doc(row.fixtureId)
    //   .set(row.toFirestoreMap(), SetOptions(merge: true));
  }
}
