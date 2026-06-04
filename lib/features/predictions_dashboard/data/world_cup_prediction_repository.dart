import '../../../../core/network/api_client.dart';
import '../models/world_cup_prediction_model.dart';

class WorldCupPredictionRepository {
  Future<WorldCupPredictionsResponse> loadWorldCupPredictions({int? roomId}) async {
    final res = await ApiClient.instance.get(
      '/worldcup/predictions' + (roomId != null ? '?room_id=$roomId' : ''),
    );
    return WorldCupPredictionsResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> submitWinner(String predictedWinnerCountry, {int? roomId}) async {
    await ApiClient.instance.post(
      '/worldcup/winner',
      data: {
        'predicted_winner_country': predictedWinnerCountry,
        if (roomId != null) 'room_id': roomId,
      },
    );
  }

  Future<void> submitGroupQualifiers(
    String groupLetter,
    List<String> predictedQualifiers, {
    int? roomId,
  }) async {
    await ApiClient.instance.post(
      '/worldcup/groups',
      data: {
        'group_letter': groupLetter,
        'predicted_qualifiers': predictedQualifiers,
        if (roomId != null) 'room_id': roomId,
      },
    );
  }
}

