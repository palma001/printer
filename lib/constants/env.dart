import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvVariables {
  static String? get apiUrl => dotenv.env['API_URL'] ?? '';
  static String? get pusherAppKey => dotenv.env['PUSHER_APP_KEY'] ?? '';
  static String? get pusherCluster => dotenv.env['PUSHER_CLUSTER'] ?? '';
  static String? get channel => dotenv.env['CHANNEL'] ?? '';
  static String? get eventName => dotenv.env['EVENT_NAME'] ?? '';
}
