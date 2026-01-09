import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hata Mesajlarını Türkçeye Çeviren Fonksiyon
  String _mapErrorMessage(FirebaseAuthException e) {
    print("Hata Kodu: ${e.code}"); 
    switch (e.code) {
      case 'user-not-found':
        return 'Böyle bir kullanıcı bulunamadı. Lütfen kayıt olun.';
      case 'wrong-password':
        return 'Girdiğiniz şifre hatalı.';
      case 'invalid-credential': 
      case 'invalid-login-credentials':
        return 'E-posta veya şifre hatalı. Lütfen kontrol edin.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz bir e-posta adresi girdiniz.';
      case 'weak-password':
        return 'Şifreniz çok zayıf. En az 6 karakter kullanın.';
      case 'operation-not-allowed':
        return 'Bu işlem şu an yapılamıyor.';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin.';
      case 'too-many-requests':
        return 'Çok fazla başarısız deneme yaptınız. Lütfen biraz bekleyin.';
      default:
        return 'Bir hata oluştu: ${e.message}';
    }
  }

  // Kayıt Olma
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      await _firestore.collection('users').doc(user!.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'profilePic': 'https://ui-avatars.com/api/?name=$name&background=random',
        'dailyGoalMinutes': 60,
      });
      return null; 
    } on FirebaseAuthException catch (e) {
      return _mapErrorMessage(e); 
    } catch (e) {
      return "Beklenmedik bir hata: $e";
    }
  }

  // Giriş Yapma
  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; 
    } on FirebaseAuthException catch (e) {
      return _mapErrorMessage(e); 
    } catch (e) {
      return "Beklenmedik bir hata: $e";
    }
  }

  // Çıkış Yapma
  Future<void> signOut() async {
    await _auth.signOut();
  }
}