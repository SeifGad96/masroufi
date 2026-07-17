import 'package:firebase_auth/firebase_auth.dart';
import 'package:masroufi/features/categories/data/data_sources/category_data_source.dart';



class AuthDataSource {
  final FirebaseAuth _auth;
  final CategoryDataSource _categoryDataSource;

  AuthDataSource({
    FirebaseAuth? auth,
    CategoryDataSource? categoryDataSource,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _categoryDataSource = categoryDataSource ?? CategoryDataSource();

  

  
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  
  User? get currentUser => _auth.currentUser;

  

  
  
  Future<User> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    
    _categoryDataSource.seedStarterCategories(user.uid).catchError((_) {});

    return user;
  }

  
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

  
  Future<void> signOut() => _auth.signOut();
}
