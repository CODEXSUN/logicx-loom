import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/api/logicx_loom_api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.api, required this.onSignedIn, super.key});

  final LogicXLoomApi api;
  final ValueChanged<UserSession> onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final Future<ApiHealth> _health;
  String? _error;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _health = widget.api.health();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _error = null;
      _isSigningIn = true;
    });
    try {
      final session = await widget.api.signIn(
        email: _email.text,
        password: _password.text,
      );
      widget.onSignedIn(session);
    } on LogicXLoomApiException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not connect to LogicX Loom.');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: SizedBox(
                      height: 76,
                      width: 84,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/logo.svg',
                            height: 72,
                            width: 72,
                          ),
                          Positioned(
                            right: 0,
                            top: -2,
                            child: FutureBuilder<ApiHealth>(
                              future: _health,
                              builder: (context, snapshot) {
                                return _ApiOnlineIndicator(
                                  isOnline: snapshot.data?.isHealthy == true,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Welcome', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    onSubmitted: (_) => _isSigningIn ? null : _signIn(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isSigningIn ? null : _signIn,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _isSigningIn
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(),
                            )
                          : const Text('Sign in'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApiOnlineIndicator extends StatelessWidget {
  const _ApiOnlineIndicator({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? const Color(0xFF9BB3FF) : const Color(0xFF596174);
    final label = isOnline ? 'LogicX Loom API online' : 'Checking API status';

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          height: 13,
          width: 13,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF060A18), width: 2),
            boxShadow: isOnline
                ? const [
                    BoxShadow(
                      color: Color(0x80305DDD),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
