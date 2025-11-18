import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:muscleup/data/services/storage_service.dart';

class AccountDeletionService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final StorageService _storageService = StorageService();

  /// Delete user account and all associated data
  /// This includes:
  /// - User document from Firestore
  /// - Signature from Firebase Storage
  /// - Contract from Firebase Storage
  /// - Firebase Auth account
  Future<void> deleteAccount(String userId) async {
    try {
      // 1. Delete user data from Firestore
      await _deleteUserData(userId);

      // 2. Delete user files from Storage
      await _deleteUserFiles(userId);

      // 3. Sign out from Google Sign In (if applicable)
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        // Ignore errors if user wasn't signed in with Google
      }

      // 4. Delete Firebase Auth account
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Delete user document from Firestore
  Future<void> _deleteUserData(String userId) async {
    try {
      final firestoreInstance = FirebaseFirestore.instance;
      await firestoreInstance.collection('users').doc(userId).delete();
    } catch (e) {
      // Log error but continue with other deletions
      print('Warning: Failed to delete user data from Firestore: $e');
      // Re-throw if it's a critical error, otherwise continue
      if (e.toString().contains('permission-denied')) {
        rethrow;
      }
    }
  }

  /// Delete user files from Firebase Storage
  Future<void> _deleteUserFiles(String userId) async {
    try {
      // Delete signature file
      try {
        await _storageService.deleteFile('signatures/$userId.png');
      } catch (e) {
        // File might not exist, continue
        print('Warning: Could not delete signature file: $e');
      }

      // Delete contract file
      try {
        await _storageService.deleteFile('contracts/$userId.txt');
      } catch (e) {
        // File might not exist, continue
        print('Warning: Could not delete contract file: $e');
      }
    } catch (e) {
      // Log error but continue with account deletion
      print('Warning: Failed to delete some user files: $e');
    }
  }
}

