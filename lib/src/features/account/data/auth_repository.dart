import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/result/app_result.dart';
import '../../../core/utils/app_log.dart';

/// Minimal public user profile (Firebase User never reaches UI).
class AppUser {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  factory AppUser.fromFirebase(User user) => AppUser(
    uid: user.uid,
    displayName: user.displayName,
    email: user.email,
    photoUrl: user.photoURL,
  );
}

/// Auth contract (abstract for test fakes; production = Firebase below).
abstract class AuthRepository {
  Stream<AppUser?> authChanges();
  AppUser? get currentUser;
  Future<AppResult<AppUser>> signInWithGoogle();
  Future<void> signOut();
}

/// Google Sign-In via google_sign_in 7.x API (singleton + initialize +
/// authenticate; no signIn()/accessToken — removed upstream).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  bool _googleInitialized = false;

  @override
  Stream<AppUser?> authChanges() =>
      _auth.authStateChanges().map((u) => u == null ? null : AppUser.fromFirebase(u));

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : AppUser.fromFirebase(u);
  }

  @override
  Future<AppResult<AppUser>> signInWithGoogle() async {
    try {
      if (!_googleInitialized) {
        await _google.initialize();
        _googleInitialized = true;
      }
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return const AppErr('Login dibatalkan.');
      }
      final cred = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      final user = cred.user;
      if (user == null) return const AppErr('Login gagal, coba lagi.');
      appLog('auth signed in ${user.uid}');
      return AppOk(AppUser.fromFirebase(user));
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
          return const AppErr('Login dibatalkan.');
        default:
          appLog('google sign-in failed: ${e.code}');
          return const AppErr('Login Google gagal, coba lagi.');
      }
    } on FirebaseAuthException catch (e) {
      appLog('firebase auth failed: ${e.code}');
      return AppErr(_friendlyAuthError(e.code));
    } catch (e) {
      appLog('sign-in failed: $e');
      return const AppErr('Login gagal, coba lagi.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (e) {
      appLog('google sign-out failed: $e');
    }
    await _auth.signOut();
  }

  String _friendlyAuthError(String code) {
    if (code.contains('api-not-available') ||
        code.contains('ApiException: 10')) {
      return 'SHA-1 belum terdaftar (lihat README).';
    }
    if (code.contains('network')) {
      return 'Tidak ada koneksi — coba lagi.';
    }
    return 'Login gagal ($code).';
  }
}
