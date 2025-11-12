import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:muscleup/data/models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user document by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Create or update user
  Future<void> setUser(String uid, UserModel user, {bool isNewUser = false}) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      
      if (isNewUser) {
        await docRef.set({
          ...user.toFirestore(),
          'created_at': FieldValue.serverTimestamp(),
        });
      } else {
        await docRef.set(user.toFirestore(), SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to save user: $e');
    }
  }

  // Update user fields
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Update last login
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'last_login': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignore error if document doesn't exist
    }
  }

  // Create initial user from Firebase Auth
  Future<UserModel> createInitialUser(User firebaseUser) async {
    final user = UserModel(
      email: firebaseUser.email!,
      name: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      role: 'user',
      status: 'active',
    );

    await setUser(firebaseUser.uid, user, isNewUser: true);
    return user;
  }

  // Check if user profile is complete
  Future<bool> isProfileComplete(String uid) async {
    final user = await getUser(uid);
    return user?.isProfileComplete ?? false;
  }
}

