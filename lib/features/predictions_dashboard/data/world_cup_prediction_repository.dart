import '../../../../core/network/api_client.dart';
import '../models/world_cup_prediction_model.dart';

class WorldCupPredictionRepository {
  Future<WorldCupPredictionsResponse> loadWorldCupPredictions() async {
    final res = await ApiClient.instance.get('/worldcup/predictions');
    return WorldCupPredictionsResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> submitWinner(String predictedWinnerCountry) async {
    await ApiClient.instance.post(
      '/worldcup/winner',
      data: {
        'predicted_winner_country': predictedWinnerCountry,
      },
    );
  }

  Future<void> submitGroupQualifiers(String groupLetter, List<String> predictedQualifiers) async {
    await ApiClient.instance.post(
      '/worldcup/groups',
      data: {
        'group_letter': groupLetter,
        'predicted_qualifiers': predictedQualifiers,
      },
    );
  }
}
