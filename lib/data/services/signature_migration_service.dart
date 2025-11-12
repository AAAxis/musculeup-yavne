import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:muscleup/data/services/storage_service.dart';
import 'package:muscleup/data/services/firestore_service.dart';

class SignatureMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();

  /// Migrate users with base64 signatures to Firebase Storage
  /// This should be called once during app initialization
  Future<void> migrateSignaturesToStorage() async {
    try {
      // Query users who have base64 signatures but no storage URL
      final querySnapshot = await _firestore
          .collection('users')
          .where('contract_signature_base64', isNotEqualTo: null)
          .where('contract_signature_url', isEqualTo: null)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('✅ No signatures need migration');
        return;
      }

      print('🔄 Found ${querySnapshot.docs.length} signatures to migrate');

      for (final doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          final userId = doc.id;
          final base64Signature = data['contract_signature_base64'] as String?;

          if (base64Signature != null && base64Signature.isNotEmpty) {
            print('🔄 Migrating signature for user: $userId');

            // Upload to Firebase Storage
            final signatureUrl = await _storageService.uploadSignature(
              userId,
              base64Signature,
            );

            // Update user document with storage URL and remove base64
            await _firestoreService.updateUser(userId, {
              'contract_signature_url': signatureUrl,
              'contract_signature_base64': FieldValue.delete(),
            });

            print('✅ Migrated signature for user: $userId');
          }
        } catch (e) {
          print('❌ Failed to migrate signature for user ${doc.id}: $e');
          // Continue with other users even if one fails
        }
      }

      print('✅ Signature migration completed');
    } catch (e) {
      print('❌ Signature migration failed: $e');
      // Don't throw - this is a background operation
    }
  }

  /// Check if a specific user needs signature migration
  Future<bool> userNeedsSignatureMigration(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;
      final hasBase64 = data['contract_signature_base64'] != null;
      final hasUrl = data['contract_signature_url'] != null;

      return hasBase64 && !hasUrl;
    } catch (e) {
      print('❌ Error checking signature migration status: $e');
      return false;
    }
  }

  /// Migrate signature for a specific user
  Future<void> migrateUserSignature(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final base64Signature = data['contract_signature_base64'] as String?;

      if (base64Signature != null && base64Signature.isNotEmpty) {
        print('🔄 Migrating signature for user: $userId');

        // Upload to Firebase Storage
        final signatureUrl = await _storageService.uploadSignature(
          userId,
          base64Signature,
        );

        // Update user document with storage URL and remove base64
        await _firestoreService.updateUser(userId, {
          'contract_signature_url': signatureUrl,
          'contract_signature_base64': FieldValue.delete(),
        });

        print('✅ Migrated signature for user: $userId');
      }
    } catch (e) {
      print('❌ Failed to migrate signature for user $userId: $e');
      rethrow;
    }
  }
}
