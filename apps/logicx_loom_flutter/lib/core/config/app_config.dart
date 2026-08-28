enum LogicXLoomEnvironment { local, cloud }

class AppConfig {
  const AppConfig._();

  static const cloudApiUrl = String.fromEnvironment(
    'LOGICX_LOOM_CLOUD_API_URL',
    defaultValue: 'https://log.logicx.in/api/platform',
  );

  static const localApiUrl = String.fromEnvironment(
    'LOGICX_LOOM_LOCAL_API_URL',
    defaultValue: 'http://10.0.2.2:9350',
  );

  static const defaultEnvironmentName = String.fromEnvironment(
    'LOGICX_LOOM_DEFAULT_ENVIRONMENT',
    defaultValue: 'cloud',
  );

  static const allowEnvironmentSwitch = bool.fromEnvironment(
    'LOGICX_LOOM_ALLOW_ENVIRONMENT_SWITCH',
    defaultValue: true,
  );

  static const developmentAutoLogin = bool.fromEnvironment(
    'LOGICX_LOOM_DEVELOPMENT_AUTO_LOGIN',
    defaultValue: false,
  );

  static const updateManifestUrl = String.fromEnvironment(
    'LOGICX_LOOM_UPDATE_URL',
    defaultValue: 'https://log.logicx.in/storage/mobile/release/update.json',
  );

  static LogicXLoomEnvironment get defaultEnvironment =>
      defaultEnvironmentName.toLowerCase() == 'local'
      ? LogicXLoomEnvironment.local
      : LogicXLoomEnvironment.cloud;

  static String apiUrlFor(LogicXLoomEnvironment environment) =>
      environment == LogicXLoomEnvironment.local ? localApiUrl : cloudApiUrl;

  static bool canAutoLoginForDevelopment(LogicXLoomEnvironment environment) {
    final host = Uri.parse(apiUrlFor(environment)).host;
    return developmentAutoLogin &&
        environment == LogicXLoomEnvironment.local &&
        (host == '10.0.2.2' || host == '127.0.0.1' || host == 'localhost');
  }
}
