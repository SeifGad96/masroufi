import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Waiting for the first auth state change event (app startup).
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// An auth operation (sign in / sign up / sign out) is in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// The user is signed in.
class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user.uid];
}

/// No user is signed in.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation failed.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
