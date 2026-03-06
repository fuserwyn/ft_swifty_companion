import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get uid => dotenv.env['INTRA_UID']?.trim() ?? '';
  static String get secret => dotenv.env['INTRA_SECRET']?.trim() ?? '';

  static bool get isConfigured => uid.isNotEmpty && secret.isNotEmpty;
}
