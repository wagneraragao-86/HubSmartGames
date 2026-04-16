import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream para monitorar mudanças no estado de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Getter para o usuário atual
  User? get currentUser => _auth.currentUser;

  // Login com Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Iniciar o processo de login do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // Usuário cancelou o login
        return null;
      }

      // Obter as credenciais de autenticação
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Criar credencial do Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Fazer login no Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      return userCredential;
    } catch (e) {
      print('Erro no login com Google: $e');
      return null;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Erro no logout: $e');
    }
  }

  // Atualizar perfil do usuário
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await _auth.currentUser?.updateDisplayName(displayName);
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      print('Erro ao atualizar perfil: $e');
      rethrow;
    }
  }

  // Verificar se está logado
  bool get isSignedIn => _auth.currentUser != null;

  // Obter dados do usuário
  String? get userId => _auth.currentUser?.uid;
  String? get userName => _auth.currentUser?.displayName;
  String? get userEmail => _auth.currentUser?.email;
  String? get userPhotoUrl => _auth.currentUser?.photoURL;
}
