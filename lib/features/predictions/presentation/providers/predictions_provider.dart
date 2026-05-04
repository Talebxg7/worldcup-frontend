import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../matches/data/models/match_model.dart';
import '../../../../core/network/api_client.dart';

final predictionsProvider = AsyncNotifierProvider<PredictionsNotifier, List<PredictionModel>>(
  PredictionsNotifier.new,
);

class PredictionsNotifier extends AsyncNotifier<List<PredictionModel>> {
  @override
  Future<List<PredictionModel>> build() async {
    return _fetchPredictions();
  }

  Future<List<PredictionModel>> _fetchPredictions() async {
    final response = await ApiClient.instance.get('/predictions/mine');
    final list = response.data as List;
    return list.map((e) => PredictionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> submitPrediction({
    required int matchId,
    required int homeScore,
    required int awayScore,
  }) async {
    await ApiClient.instance.post('/predictions', data: {
      'match_id': matchId,
      'home_score': homeScore,
      'away_score': awayScore,
    });
    // Refresh predictions list
    state = await AsyncValue.guard(_fetchPredictions);
  }

  Future<void> updatePrediction({
    required int predictionId,
    required int homeScore,
    required int awayScore,
  }) async {
    await ApiClient.instance.put('/predictions/$predictionId', data: {
      'home_score': homeScore,
      'away_score': awayScore,
    });
    state = await AsyncValue.guard(_fetchPredictions);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchPredictions);
  }
}
