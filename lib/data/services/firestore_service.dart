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

  // Get raw user document data (for fields not in UserModel)
  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user document: $e');
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

  // Check if user has existing booster request
  Future<bool> hasExistingBoosterRequest(String userEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection('coachNotifications')
          .where('user_email', isEqualTo: userEmail)
          .where('notification_type', isEqualTo: 'booster_request')
          .where('is_read', isEqualTo: false)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Failed to check existing booster request: $e');
    }
  }

  // Create coach notification (for booster requests, etc.)
  Future<void> createCoachNotification({
    required String userEmail,
    required String userName,
    required String coachEmail,
    required String notificationType,
    required String notificationTitle,
    required String notificationMessage,
    Map<String, dynamic>? notificationDetails,
  }) async {
    try {
      await _firestore.collection('coachNotifications').add({
        'user_email': userEmail,
        'user_name': userName,
        'coach_email': coachEmail,
        'notification_type': notificationType,
        'notification_title': notificationTitle,
        'notification_message': notificationMessage,
        if (notificationDetails != null) 'notification_details': notificationDetails,
        'is_read': false,
        'created_date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create coach notification: $e');
    }
  }

  // Add weight entry
  Future<void> addWeightEntry({
    required String userEmail,
    required double weight,
    required String date,
    required String time,
  }) async {
    try {
      await _firestore.collection('weight_entries').add({
        'user_email': userEmail,
        'weight': weight,
        'date': date,
        'time': time,
        'created_date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add weight entry: $e');
    }
  }

  // Add water tracking entry
  Future<void> addWaterEntry({
    required String userEmail,
    required int amountMl,
    required String date,
    required String time,
    required String containerType,
    int? dailyGoalMl,
  }) async {
    try {
      await _firestore.collection('waterTracking').add({
        'user_email': userEmail,
        'amount_ml': amountMl,
        'date': date,
        'time_logged': time,
        'container_type': containerType,
        if (dailyGoalMl != null) 'daily_goal_ml': dailyGoalMl,
        'shared_with_coach': false,
        'viewed_by_coach': false,
        'created_date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add water entry: $e');
    }
  }

  // Get water entries for a user
  Future<List<Map<String, dynamic>>> getWaterEntries(String userEmail, {int limit = 100}) async {
    try {
      final querySnapshot = await _firestore
          .collection('waterTracking')
          .where('user_email', isEqualTo: userEmail)
          .orderBy('created_date', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get water entries: $e');
    }
  }

  // Get weight entries for a user
  Future<List<Map<String, dynamic>>> getWeightEntries(String userEmail, {int limit = 100}) async {
    try {
      final querySnapshot = await _firestore
          .collection('weight_entries')
          .where('user_email', isEqualTo: userEmail)
          .orderBy('created_date', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get weight entries: $e');
    }
  }

  // Delete water entry
  Future<void> deleteWaterEntry(String entryId) async {
    try {
      await _firestore.collection('waterTracking').doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete water entry: $e');
    }
  }

  // Delete weight entry
  Future<void> deleteWeightEntry(String entryId) async {
    try {
      await _firestore.collection('weight_entries').doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete weight entry: $e');
    }
  }

  // Add meal/calorie tracking entry
  Future<void> addMealEntry({
    required String userEmail,
    required String mealDescription,
    required String date,
    String? mealType,
    int? estimatedCalories,
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    String? mealImage,
    String? mealTimestamp,
    String? coachNote,
    bool sharedWithCoach = false,
  }) async {
    try {
      await _firestore.collection('calorie_tracking').add({
        'user_email': userEmail,
        'date': date,
        'meal_type': mealType ?? 'ארוחה כללית',
        'meal_description': mealDescription,
        'meal_timestamp': mealTimestamp ?? FieldValue.serverTimestamp(),
        'estimated_calories': estimatedCalories,
        'protein_grams': proteinGrams,
        'carbs_grams': carbsGrams,
        'fat_grams': fatGrams,
        if (mealImage != null) 'meal_image': mealImage,
        if (coachNote != null && coachNote.isNotEmpty) 'coach_note': coachNote,
        'shared_with_coach': sharedWithCoach,
        'viewed_by_coach': false,
        'ai_assisted': true,
        'created_date': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add meal entry: $e');
    }
  }

  // Get meal entries for a user
  Future<List<Map<String, dynamic>>> getMealEntries(String userEmail, {int limit = 100}) async {
    try {
      final querySnapshot = await _firestore
          .collection('calorie_tracking')
          .where('user_email', isEqualTo: userEmail)
          .orderBy('created_date', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get meal entries: $e');
    }
  }

  // Get workouts for a user
  Future<List<Map<String, dynamic>>> getWorkouts(String userEmail, {int limit = 100}) async {
    try {
      final querySnapshot = await _firestore
          .collection('workouts')
          .where('created_by', isEqualTo: userEmail)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      
      return querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      // If orderBy fails, try without it
      try {
        final querySnapshot = await _firestore
            .collection('workouts')
            .where('created_by', isEqualTo: userEmail)
            .limit(limit)
            .get();
        
        final workouts = querySnapshot.docs.map((doc) => {
          'id': doc.id,
          ...doc.data(),
        }).toList();
        
        // Sort manually by date
        workouts.sort((a, b) {
          final dateA = a['date'] as String? ?? '';
          final dateB = b['date'] as String? ?? '';
          return dateB.compareTo(dateA);
        });
        
        return workouts;
      } catch (e2) {
        throw Exception('Failed to get workouts: $e2');
      }
    }
  }

  // Save recipe to recipes collection
  Future<String> saveRecipe({
    required String userEmail,
    required Map<String, dynamic> recipeData,
  }) async {
    try {
      final recipeDoc = await _firestore.collection('recipes').add({
        ...recipeData,
        'creator_email': userEmail,
        'is_public': false,
        'created_date': FieldValue.serverTimestamp(),
      });
      return recipeDoc.id;
    } catch (e) {
      throw Exception('Failed to save recipe: $e');
    }
  }

  // Add recipe to favorites
  Future<void> addToFavorites({
    required String userEmail,
    required String recipeId,
  }) async {
    try {
      // Check if already favorited
      final existing = await _firestore
          .collection('favoriteRecipes')
          .where('user_email', isEqualTo: userEmail)
          .where('recipe_id', isEqualTo: recipeId)
          .get();

      if (existing.docs.isEmpty) {
        await _firestore.collection('favoriteRecipes').add({
          'user_email': userEmail,
          'recipe_id': recipeId,
          'created_date': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  // Remove recipe from favorites
  Future<void> removeFromFavorites({
    required String userEmail,
    required String recipeId,
  }) async {
    try {
      final favorites = await _firestore
          .collection('favoriteRecipes')
          .where('user_email', isEqualTo: userEmail)
          .where('recipe_id', isEqualTo: recipeId)
          .get();

      for (var doc in favorites.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  // Get favorite recipes for user
  Future<List<Map<String, dynamic>>> getFavoriteRecipes(String userEmail) async {
    try {
      final favorites = await _firestore
          .collection('favoriteRecipes')
          .where('user_email', isEqualTo: userEmail)
          .get();

      if (favorites.docs.isEmpty) {
        return [];
      }

      final recipeIds = favorites.docs.map((doc) => doc.data()['recipe_id'] as String).toList();
      final recipes = <Map<String, dynamic>>[];

      for (var recipeId in recipeIds) {
        try {
          final recipeDoc = await _firestore.collection('recipes').doc(recipeId).get();

          if (recipeDoc.exists) {
            final recipeData = recipeDoc.data()!;
            recipeData['id'] = recipeDoc.id;
            recipes.add(recipeData);
          }
        } catch (e) {
          print('Error loading recipe $recipeId: $e');
        }
      }

      return recipes;
    } catch (e) {
      throw Exception('Failed to get favorite recipes: $e');
    }
  }

  // Get all recipes (public and user's recipes)
  Future<List<Map<String, dynamic>>> getRecipes(String? userEmail) async {
    try {
      final publicRecipes = await _firestore
          .collection('recipes')
          .where('is_public', isEqualTo: true)
          .get();

      final recipes = <Map<String, dynamic>>[];
      
      for (var doc in publicRecipes.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        recipes.add(data);
      }

      if (userEmail != null) {
        final userRecipes = await _firestore
            .collection('recipes')
            .where('creator_email', isEqualTo: userEmail)
            .get();

        for (var doc in userRecipes.docs) {
          // Avoid duplicates
          if (!recipes.any((r) => r['id'] == doc.id)) {
            final data = doc.data();
            data['id'] = doc.id;
            recipes.add(data);
          }
        }
      }

      return recipes;
    } catch (e) {
      throw Exception('Failed to get recipes: $e');
    }
  }

  // Get all exercises from exerciseDefinitions collection
  Future<List<Map<String, dynamic>>> getExercises({String? muscleGroup, String? category}) async {
    try {
      CollectionReference<Map<String, dynamic>> collectionRef = _firestore.collection('exerciseDefinitions');
      Query<Map<String, dynamic>> query = collectionRef;
      
      // Apply filters if provided
      if (muscleGroup != null && muscleGroup.isNotEmpty) {
        query = query.where('muscle_group', isEqualTo: muscleGroup);
      }
      
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Failed to get exercises: $e');
    }
  }

  // Get exercise by ID
  Future<Map<String, dynamic>?> getExerciseById(String exerciseId) async {
    try {
      final doc = await _firestore.collection('exerciseDefinitions').doc(exerciseId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get exercise: $e');
    }
  }
}

