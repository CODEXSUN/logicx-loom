import 'package:flutter/material.dart';

import '../core/api/logicx_loom_api.dart';
import '../core/auth/session_store.dart';
import '../core/config/app_config.dart';
import '../core/update/app_update_dialog.dart';
import '../core/update/app_update_service.dart';
import '../features/auth/login_page.dart';
import '../features/dashboard/dashboard_page.dart';

class LogicXLoomFlutterApp extends StatefulWidget {
  const LogicXLoomFlutterApp({super.key});

  @override
  State<LogicXLoomFlutterApp> createState() => _LogicXLoomFlutterAppState();
}

class _LogicXLoomFlutterAppState extends State<LogicXLoomFlutterApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _sessionStore = const SessionStore();
  late LogicXLoomEnvironment _environment;
  late LogicXLoomApi _api;
  UserSession? _session;
  var _isStarting = true;
  var _updateChecked = false;

  @override
  void initState() {
    super.initState();
    _environment = AppConfig.defaultEnvironment;
    _api = LogicXLoomApi(AppConfig.apiUrlFor(_environment));
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    try {
      final token = await _sessionStore.readToken();
      if (token != null) {
        _session = UserSession(
          accessToken: token,
          profile: await _api.session(token),
        );
      } else if (AppConfig.canAutoLoginForDevelopment(_environment)) {
        _session = await _api.developmentSignIn();
        await _sessionStore.saveToken(_session!.accessToken);
      }
    } catch (_) {
      await _sessionStore.clear();
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
      }
    }
  }

  Future<void> _checkForUpdate() async {
    if (_updateChecked || !mounted) return;
    _updateChecked = true;
    final service = AppUpdateService(Uri.parse(AppConfig.updateManifestUrl));
    try {
      final update = await service.check();
      if (update == null || !mounted) return;
      final navigatorContext = _navigatorKey.currentContext;
      if (navigatorContext == null || !navigatorContext.mounted) return;
      await showDialog<void>(
        context: navigatorContext,
        barrierDismissible: !update.required,
        builder: (context) => AppUpdateDialog(update: update, service: service),
      );
    } catch (_) {
      // Update checks must not block login or machine data synchronization.
    }
  }

  Future<void> _signedIn(UserSession session) async {
    await _sessionStore.saveToken(session.accessToken);
    if (mounted) setState(() => _session = session);
  }

  void _selectEnvironment(LogicXLoomEnvironment environment) {
    if (_environment == environment) return;
    setState(() {
      _environment = environment;
      _api = LogicXLoomApi(AppConfig.apiUrlFor(environment));
    });
  }

  Future<void> _signOut() async {
    await _sessionStore.clear();
    if (mounted) setState(() => _session = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'LogicX Loom',
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF4169E1),
          primary: const Color(0xFF5B7CFA),
          surface: const Color(0xFF0D1428),
        ),
        scaffoldBackgroundColor: const Color(0xFF060A18),
        cardTheme: const CardThemeData(color: Color(0xFF0D1428)),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF080E20),
          indicatorColor: Color(0xFF1D3470),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0D1428),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF26345A)),
          ),
        ),
        useMaterial3: true,
      ),
      home: _isStarting
          ? const _StartingPage()
          : _session == null
          ? LoginPage(
              key: ValueKey(_environment),
              api: _api,
              environment: _environment,
              onEnvironmentChanged: _selectEnvironment,
              onSignedIn: _signedIn,
            )
          : DashboardPage(api: _api, session: _session!, onSignOut: _signOut),
    );
  }
}

class _StartingPage extends StatelessWidget {
  const _StartingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
