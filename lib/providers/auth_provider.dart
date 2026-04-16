import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  User? _user;
  bool _isLoading = false;

  AuthProvider(this._authService, {required StorageService storageService})
      : _storageService = storageService {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSignedIn => _user != null;

  String? get userId => _user?.uid;
  String? get userName => _user?.displayName;
  String? get userEmail => _user?.email;
  String? get userPhotoUrl => _user?.photoURL;

  void _onAuthStateChanged(User? user) {
    _user = user;
    notifyListeners();

    if (user != null) {
      // Usuário fez login, sincronizar dados
      _syncDataAfterLogin();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userCredential = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return userCredential != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Erro no login: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      // Limpar dados locais quando fazer logout
      await _storageService.close();
    } catch (e) {
      print('Erro no logout: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.updateProfile(displayName: displayName, photoURL: photoURL);
      // Recarregar o usuário para refletir as mudanças
      await _authService.currentUser?.reload();
      _user = _authService.currentUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Erro ao atualizar perfil: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _syncDataAfterLogin() async {
    if (_user != null) {
      try {
        // Carregar dados do Firebase
        await _storageService.loadFromFirebase();
        // Sincronizar dados locais com Firebase
        await _storageService.syncWithFirebase();
      } catch (e) {
        print('Erro ao sincronizar dados: $e');
      }
    }
  }
}
