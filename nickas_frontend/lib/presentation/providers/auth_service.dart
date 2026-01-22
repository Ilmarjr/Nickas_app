import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'openid', 'profile'],
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  GoogleSignInAccount? _currentUser;
  GoogleSignInAccount? get currentUser => _currentUser;
  
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentUser = account;
      notifyListeners();
      if (account != null) {
        _storeToken(account);
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> signIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      if (kDebugMode) {
        print('Sign in failed: $error');
      }
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.delete(key: 'jwt_token');
  }

  Future<void> _storeToken(GoogleSignInAccount account) async {
    // Here we would typically send account.authentication tokens to Backend
    // and receive our own JWT. For now, we simulate simplified flow.
    final auth = await account.authentication;
    if (auth.idToken != null) {
       // Ideally: Call Backend API to exchange Google ID Token for Backend JWT
       // For MVP: Just print or store stub
       await _storage.write(key: 'google_id_token', value: auth.idToken);
    }
  }
}
