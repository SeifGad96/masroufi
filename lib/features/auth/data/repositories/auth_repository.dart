import 'package:firebase_auth/firebase_auth.dart';
import 'package:masroufi/features/categories/data/repositories/category_repository.dart';

/// Handles all Firebase Auth operations for the app.
/// PRD §8.1 — email/password, session persistence (auto-login on relaunch).
class AuthRepository {
  final FirebaseAuth _auth;
  final CategoryRepository _categoryRepository;

  AuthRepository({
    FirebaseAuth? auth,
    CategoryRepository? categoryRepository,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _categoryRepository = categoryRepository ?? CategoryRepository();

  // ── Streams ───────────────────────────────────────────────────────────────

  /// Emits the current user on every auth state change (login, logout, session restore).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the currently signed-in user, or null.
  User? get currentUser => _auth.currentUser;

  // ── Auth operations ───────────────────────────────────────────────────────

  /// Creates a new account with [email] and [password].
  /// On success, seeds the 7 starter categories for the new user.
  Future<User> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    // Seed starter categories in the background — don't block sign-up UX
    _categoryRepository.seedStarterCategories(user.uid).catchError((_) {});

    return user;
  }

  /// Signs in with [email] and [password].
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return credential.user!;
  }

  /// Signs out the current user.
  Future<void> signOut() => _auth.signOut();
}
