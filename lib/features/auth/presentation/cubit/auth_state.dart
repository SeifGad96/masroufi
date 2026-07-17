import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState {
  const AuthState();
}


class AuthInitial extends AuthState {
  const AuthInitial();
}


class AuthLoading extends AuthState {
  const AuthLoading();
}


class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
}


class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}


class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}