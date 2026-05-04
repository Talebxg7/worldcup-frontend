import 'dart:convert';
import 'lib/features/auth/data/models/user_model.dart';

void main() {
  final jsonString = '{"id":5,"username":"testuser999","email":"testuser999@test.com","is_admin":false,"is_premium":false,"total_points":0,"rank":0,"total_predictions":0,"exact_scores":0,"correct_results":0,"avatar_url":null,"created_at":"2026-04-28T22:39:34.283Z"}';
  try {
    final map = jsonDecode(jsonString);
    final user = UserModel.fromJson(map);
    print("Success: \${user.username}");
  } catch (e, st) {
    print("Error: \$e");
    print(st);
  }
}
