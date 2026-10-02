import 'package:flutter/material.dart';
import 'package:timelines/timeline/local_photo_store.dart';
import 'package:timelines/timeline/local_timeline_repository.dart';
import 'package:timelines/timeline/timeline_list_screen.dart';
import 'package:timelines/timeline/timeline_repository.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_factory.dart';
import 'data/app_database.dart' as db;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db.AppDatabase database = db.AppDatabase();
  await database.customSelect('SELECT 1').get();

  final LocalPhotoStore photoStore = await LocalPhotoStore.create();
  final TimelineRepository repository = LocalTimelineRepository(
    database,
    photoStore,
  );

  runApp(
    MainApp(
      controller: AuthController(createAuthRepository()),
      repository: repository,
      database: database,
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({
    required this.controller,
    required this.repository,
    required this.database,
    super.key,
  });

  final AuthController controller;
  final TimelineRepository repository;
  final db.AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timelines',
      home: AuthGate(controller: controller, repository: repository),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({required this.controller, this.repository, super.key});

  final AuthController controller;
  final TimelineRepository? repository;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isGuest = false;

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

  void _enterGuestMode() => setState(() => _isGuest = true);

  void _leaveGuestMode() => setState(() => _isGuest = false);

  void _signOut() {
    _isGuest = false;
    widget.controller.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final AuthController controller = widget.controller;
    return switch (controller.status) {
      AuthStatus.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthStatus.signedIn => _PrivateShell(
        repository: widget.repository,
        sessionEmail: controller.session?.email,
        onSignOut: _signOut,
      ),
      AuthStatus.error => _ErrorView(
        message: controller.errorMessage ?? 'Unable to sign in.',
        onRetry: controller.retry,
      ),
      AuthStatus.signedOut =>
        _isGuest
            ? _PrivateShell(
                repository: widget.repository,
                onSignIn: controller.signIn,
                onSignOut: _leaveGuestMode,
              )
            : _SignedOutView(
                onSignIn: controller.signIn,
                onGuestEntry: _enterGuestMode,
                busy: controller.operationInFlight,
              ),
    };
  }
}

class _SignedOutView extends StatelessWidget {
  const _SignedOutView({
    required this.onSignIn,
    required this.onGuestEntry,
    required this.busy,
  });

  final VoidCallback onSignIn;
  final VoidCallback onGuestEntry;
  final bool busy;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Timelines')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          FilledButton.icon(
            onPressed: busy ? null : onSignIn,
            icon: const Icon(Icons.login),
            label: const Text('Sign in with Google'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onGuestEntry,
            child: const Text('Continue as guest'),
          ),
        ],
      ),
    ),
  );
}

class _PrivateShell extends StatelessWidget {
  const _PrivateShell({
    this.sessionEmail,
    this.repository,
    this.onSignIn,
    required this.onSignOut,
  });

  final String? sessionEmail;
  final TimelineRepository? repository;
  final VoidCallback? onSignIn;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Timelines'),
      actions: <Widget>[
        if (onSignIn != null)
          TextButton(
            onPressed: onSignIn,
            child: const Text('Sign in with Google'),
          ),
        IconButton(onPressed: onSignOut, icon: const Icon(Icons.logout)),
      ],
    ),
    body: repository == null
        ? Center(
            child: Text(
              sessionEmail == null
                  ? 'Your private timelines'
                  : 'Your private timelines\n$sessionEmail',
              textAlign: TextAlign.center,
            ),
          )
        : Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  sessionEmail == null
                      ? 'Your private timelines'
                      : 'Your private timelines\n$sessionEmail',
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(child: TimelineListScreen(repository: repository!)),
            ],
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
