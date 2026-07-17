import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/data_sources/auth_data_source.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthDataSource _authDataSource;
  StreamSubscription<User?>? _authSubscription;

  AuthCubit({required AuthDataSource authDataSource})
      : _authDataSource = authDataSource,
        super(const AuthInitial()) {
    _listenToAuthChanges();
  }

  

  
  
  void _listenToAuthChanges() {
    _authSubscription = _authDataSource.authStateChanges.listen(
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
      onError: (e) => emit(const AuthUnauthenticated()),
    );
  }

  

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      await _authDataSource.signUp(email: email, password: password);
      
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_friendlyMessage(e)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      await _authDataSource.signIn(email: email, password: password);
      
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_friendlyMessage(e)));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  

  Future<void> signOut() async {
    await _authDataSource.signOut();
    
  }

  

  String _friendlyMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for that email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
