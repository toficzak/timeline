import 'package:google_sign_in/google_sign_in.dart';

class GoogleAccount {
  const GoogleAccount({required this.id, required this.email});

  final String id;
  final String email;
}

abstract interface class GoogleSignInClient {
  Future<void> initialize({String? serverClientId});

  Future<GoogleAccount?> attemptLightweightAuthentication({
    bool reportAllExceptions,
  });

  Future<GoogleAccount> authenticate();

  Future<void> signOut();
}

class PluginGoogleSignInClient implements GoogleSignInClient {
  PluginGoogleSignInClient({GoogleSignIn? googleSignIn})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;

  @override
  Future<void> initialize({String? serverClientId}) =>
      _googleSignIn.initialize(serverClientId: serverClientId);

  @override
  Future<GoogleAccount?> attemptLightweightAuthentication({
    bool reportAllExceptions = false,
  }) async {
    final GoogleSignInAccount? account =
        await _googleSignIn.attemptLightweightAuthentication(
          reportAllExceptions: reportAllExceptions,
        );
    return account == null
        ? null
        : GoogleAccount(id: account.id, email: account.email);
  }

  @override
  Future<GoogleAccount> authenticate() async {
    final GoogleSignInAccount account = await _googleSignIn.authenticate();
    return GoogleAccount(id: account.id, email: account.email);
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}
