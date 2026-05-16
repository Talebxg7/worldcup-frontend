class AppConstants {
  // API
  // static const String baseUrl = 'http://192.168.1.32:3000/api'; // Phone over Wi-Fi
  // static const String baseUrl = 'http://localhost:3000/api'; // Windows desktop / local dev
  static const String baseUrl = 'https://whowillwin-api.onrender.com/api';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode_v2';

  // Scoring
  static const int exactScorePoints = 3;
  static const int correctResultPoints = 1;

  // Prediction Deadline (hours before match)
  static const int predictionDeadlineHours = 2;

  // App Info
  static const String appName = 'World Cup 2026';
  static const String appTagline = 'Predict. Compete. Win.';

  // FIFA World Cup 2026 Groups
  static const List<String> groups = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];

  // Stages
  static const List<String> stages = [
    'Group Stage',
    'Round of 32',
    'Round of 16',
    'Quarter-Final',
    'Semi-Final',
    'Third Place',
    'Final',
  ];
}
