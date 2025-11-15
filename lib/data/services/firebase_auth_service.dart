import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:muscleup/data/services/firestore_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      // Update last login
      if (userCredential.user != null) {
        await _firestoreService.updateLastLogin(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign in with Apple (iOS only)
  Future<UserCredential?> signInWithApple() async {
    try {
      // Check if Apple Sign In is available (iOS only)
      if (!Platform.isIOS) {
        throw Exception('Apple Sign In is only available on iOS');
      }

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential from Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with the Apple credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);

      // If this is the first time signing in, update the display name if provided
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        final displayName = appleCredential.givenName != null &&
                appleCredential.familyName != null
            ? '${appleCredential.givenName} ${appleCredential.familyName}'
            : appleCredential.givenName ?? appleCredential.familyName;
        
        if (displayName != null && 
            displayName.isNotEmpty && 
            userCredential.user != null &&
            (userCredential.user!.displayName == null || 
             userCredential.user!.displayName!.isEmpty)) {
          try {
            await userCredential.user!.updateDisplayName(displayName);
            await userCredential.user!.reload();
          } catch (e) {
            // Ignore errors updating display name
            print('Warning: Could not update display name: $e');
          }
        }
      }

      // Update last login
      if (userCredential.user != null) {
        await _firestoreService.updateLastLogin(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      throw Exception('Failed to sign in with Apple: $e');
    }
  }

  // Check if user profile is complete
  Future<bool> isProfileComplete(String uid) async {
    return await _firestoreService.isProfileComplete(uid);
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // Get user display name
  String? get userDisplayName => currentUser?.displayName;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user photo URL
  String? get userPhotoUrl => currentUser?.photoURL;
}

