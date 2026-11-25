class AppConfig {
  static const String bankName = 'Sahyadri Digital Bank';

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'DEV',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  // Override at build time with: --dart-define=DEV_USER=admin --dart-define=DEV_PASS=yourpass
  static const String devUsername = String.fromEnvironment(
    'DEV_USER',
    defaultValue: 'sandy226700',
  );

  static const String devPassword = String.fromEnvironment(
    'DEV_PASS',
    defaultValue: 'ops@2026',
  );
}
