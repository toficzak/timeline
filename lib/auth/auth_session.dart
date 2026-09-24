import 'package:flutter/foundation.dart';

@immutable
class AuthSession {
  const AuthSession({required this.providerId, this.email});

  final String providerId;
  final String? email;
}
