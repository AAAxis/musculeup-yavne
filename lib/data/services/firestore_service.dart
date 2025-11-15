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

  // Update user fields (creates document if it doesn't exist)
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      // Check if document exists first
      final doc = await docRef.get();
      
      if (doc.exists) {
        // Document exists, use update
        await docRef.update({
          ...data,
          'updated_at': FieldValue.serverTimestamp(),
        });
      } else {
        // Document doesn't exist, use set with merge
        await docRef.set({
          ...data,
          'updated_at': FieldValue.serverTimestamp(),
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Update last login (only if document exists)
  Future<void> updateLastLogin(String uid) async {
    try {
      final docRef = _firestore.collection('users').doc(uid);
      // Check if document exists first
      final doc = await docRef.get();
      
      if (doc.exists) {
        // Document exists, use update
        try {
          await docRef.update({
            'last_login': FieldValue.serverTimestamp(),
          });
        } catch (updateError) {
          // If update fails (e.g., document was deleted), silently ignore
          // This can happen in race conditions
          print('Warning: Could not update last_login for user $uid: $updateError');
        }
      }
      // If document doesn't exist, silently ignore - it will be created during onboarding
    } catch (e) {
      // Silently ignore all errors - user document will be created during onboarding
      // This prevents errors for new users who haven't completed onboarding yet
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

  // Get all coaches/admins (users with role 'admin' or 'coach')
  Future<List<UserModel>> getCoaches() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', whereIn: ['admin', 'coach'])
          .get();
      
      final coaches = <UserModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final user = UserModel.fromFirestore(doc);
          if (user.email.isNotEmpty && user.name.isNotEmpty) {
            coaches.add(user);
          }
        } catch (e) {
          print('Error parsing coach document ${doc.id}: $e');
          // Continue processing other documents
        }
      }
      
      return coaches;
    } catch (e) {
      throw Exception('Failed to get coaches: $e');
    }
  }
}

