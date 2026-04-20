class AppConfig {
  static const String appName = 'Inventory';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 30000;

  // Sync
  static const int syncIntervalSeconds = 60;
  static const int maxSyncRetries = 3;

  // PIN
  static const int pinLength = 4;
  static const int pinMaxAttempts = 5;
  static const Duration pinLockDuration = Duration(minutes: 5);
}
