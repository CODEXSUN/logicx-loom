class AppConfig {
  const AppConfig._();

  static const apiUrl = String.fromEnvironment(
    'LOGICX_LOOM_API_URL',
    defaultValue: 'http://10.0.2.2:9350',
  );

  static const developmentAutoLogin = bool.fromEnvironment(
    'LOGICX_LOOM_DEVELOPMENT_AUTO_LOGIN',
    defaultValue: false,
  );

  static const updateManifestUrl = String.fromEnvironment(
    'LOGICX_LOOM_UPDATE_URL',
    defaultValue: 'https://log.logicx.in/storage/mobile/release/update.json',
  );

  static bool canAutoLoginForDevelopment() {
    final host = Uri.parse(apiUrl).host;
    return developmentAutoLogin &&
        (host == '10.0.2.2' || host == '127.0.0.1' || host == 'localhost');
  }
}
