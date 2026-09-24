/// API Endpoints & Gemini AI Configurations
class ApiEndpoints {
  ApiEndpoints._();

  /// Default Gemini Model for extraction
  static const String geminiModel = 'gemini-1.5-flash';

  /// Base Gemini URL template
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  /// Endpoint to generate content
  static String geminiGenerateUrl(String apiKey, {String model = geminiModel}) {
    return '$geminiBaseUrl/$model:generateContent?key=$apiKey';
  }

  /// Optional remote field inspection backend endpoint (for ticket syncing)
  static const String remoteSyncBaseUrl = 'https://api.field-inspection.example.com/v1';
  static const String ticketsEndpoint = '$remoteSyncBaseUrl/tickets';

  /// Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
