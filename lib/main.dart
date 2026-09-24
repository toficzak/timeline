import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_factory.dart';

void main() {
  runApp(MainApp(controller: AuthController(createAuthRepository())));
}

class MainApp extends StatelessWidget {
  const MainApp({required this.controller, super.key});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timelines',
      home: AuthGate(controller: controller),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({required this.controller, super.key});

  final AuthController controller;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.initialize();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = widget.controller;
    return switch (controller.status) {
      AuthStatus.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthStatus.signedIn => _PrivateShell(
        sessionEmail: controller.session?.email,
        onSignOut: controller.signOut,
      ),
      AuthStatus.error => _ErrorView(
        message: controller.errorMessage ?? 'Unable to sign in.',
        onRetry: controller.retry,
      ),
      AuthStatus.signedOut => _SignedOutView(
        onSignIn: controller.signIn,
        busy: controller.operationInFlight,
      ),
    };
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView({required this.onSignIn, required this.busy});

  final VoidCallback onSignIn;
  final bool busy;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Timelines')),
    body: Center(
      child: FilledButton.icon(
        onPressed: busy ? null : onSignIn,
        icon: const Icon(Icons.login),
        label: const Text('Sign in with Google'),
      ),
    ),
  );
}

class _PrivateShell extends StatelessWidget {
  const _PrivateShell({required this.sessionEmail, required this.onSignOut});

  final String? sessionEmail;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Timelines'),
      actions: <Widget>[
        IconButton(onPressed: onSignOut, icon: const Icon(Icons.logout)),
      ],
    ),
    body: Center(
      child: Text(
        sessionEmail == null
            ? 'Your private timelines'
            : 'Your private timelines\n$sessionEmail',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
