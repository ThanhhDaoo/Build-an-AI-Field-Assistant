/// Global application constants
class AppConstants {
  AppConstants._();

  static const String appName = 'Field AI Assistant';
  static const String appVersion = '1.0.0';

  // Local Storage & Database
  static const String dbName = 'field_ai_assistant.db';
  static const int dbVersion = 3;
  static const String ticketsTable = 'inspection_tickets';

  // Shared Preferences Keys
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyInspectorName = 'inspector_name';
  static const String keyAutoSyncEnabled = 'auto_sync_enabled';

  // Assets Paths
  static const String promptSystemExtraction =
      'assets/prompts/system_extraction_prompt.txt';

  // Categories
  static const List<String> categories = [
    'electrical',
    'mechanical',
    'civil',
    'safety',
    'hvac',
    'general',
  ];

  // Priority Levels
  static const List<String> priorities = [
    'low',
    'medium',
    'high',
    'critical',
  ];
}
