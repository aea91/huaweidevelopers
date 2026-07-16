import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mevcut kullanıcıyı getir
  User? get currentUser => _auth.currentUser;

  // Auth state değişikliklerini dinle
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Admin login (email/password)
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('Bu email ile kayıtlı kullanıcı bulunamadı');
        case 'wrong-password':
          throw Exception('Hatalı şifre');
        case 'invalid-email':
          throw Exception('Geçersiz email formatı');
        case 'user-disabled':
          throw Exception('Bu hesap devre dışı bırakılmış');
        default:
          throw Exception('Giriş hatası: ${e.message}');
      }
    } catch (e) {
      throw Exception('Beklenmeyen hata: $e');
    }
  }

  // Admin kaydı (ilk admin için)
  Future<UserCredential> registerAdmin(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('Şifre çok zayıf (minimum 6 karakter)');
        case 'email-already-in-use':
          throw Exception('Bu email zaten kullanımda');
        case 'invalid-email':
          throw Exception('Geçersiz email formatı');
        default:
          throw Exception('Kayıt hatası: ${e.message}');
      }
    } catch (e) {
      throw Exception('Beklenmeyen hata: $e');
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Admin kontrolü
  bool get isAdmin => currentUser != null;

  // Şifre sıfırlama emaili gönder
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Şifre sıfırlama emaili gönderilemedi: $e');
    }
  }
}
