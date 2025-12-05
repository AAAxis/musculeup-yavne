import 'dart:convert';
import 'package:http/http.dart' as http;

class ExerciseDBService {
  static const String _rapidApiBaseUrl = 'https://exercisedb-api1.p.rapidapi.com/api/v1';
  static const String _rapidApiHost = 'exercisedb-api1.p.rapidapi.com';
  static const String _fallbackBaseUrl = 'https://v2.exercisedb.dev';
  
  // Fallback API key (you should move this to environment variables)
  static const String _apiKey = '19a9c82334msh8f9441d42ac9c20p1eb287jsnf6c9f6f8eb4b';

  Future<Map<String, dynamic>> _makeRequest(String endpoint) async {
    try {
      // Try RapidAPI first
      final url = Uri.parse('$_rapidApiBaseUrl$endpoint');
      final response = await http.get(
        url,
        headers: {
          'x-rapidapi-host': _rapidApiHost,
          'x-rapidapi-key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Handle RapidAPI response format: {success: true, data: [...]}
        if (data is Map) {
          final mapData = Map<String, dynamic>.from(data);
          if (mapData['success'] == true && mapData['data'] != null) {
            return mapData;
          }
        }
        return {'success': true, 'data': data is List ? data : [data]};
      }
    } catch (e) {
      print('RapidAPI request failed: $e');
    }

    // Fallback to v2.exercisedb.dev
    try {
      final url = Uri.parse('$_fallbackBaseUrl$endpoint');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
        return {'success': true, 'data': data is List ? data : [data]};
      }
    } catch (e) {
      print('Fallback API request failed: $e');
      throw Exception('Failed to fetch from ExerciseDB API: $e');
    }

    throw Exception('Failed to fetch from ExerciseDB API');
  }

  /// Search exercises by name
  Future<List<Map<String, dynamic>>> searchExercises(String query, {int limit = 50}) async {
    try {
      final endpoint = '/exercises/search?search=${Uri.encodeComponent(query)}&limit=$limit';
      final response = await _makeRequest(endpoint);
      final data = response['data'];
      if (data is List) {
        return data.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error searching exercises: $e');
      return [];
    }
  }

  /// Get exercises by body part
  Future<List<Map<String, dynamic>>> getExercisesByBodyPart(String bodyPart, {int limit = 50}) async {
    try {
      final normalizedBodyPart = bodyPart.toUpperCase();
      final endpoint = '/exercises/bodyPart/${Uri.encodeComponent(normalizedBodyPart)}?limit=$limit';
      final response = await _makeRequest(endpoint);
      final data = response['data'];
      if (data is List) {
        return data.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching exercises by body part: $e');
      return [];
    }
  }

  /// Get exercises by equipment
  Future<List<Map<String, dynamic>>> getExercisesByEquipment(String equipment, {int limit = 50}) async {
    try {
      final normalizedEquipment = equipment.toUpperCase();
      final endpoint = '/exercises/equipment/${Uri.encodeComponent(normalizedEquipment)}?limit=$limit';
      final response = await _makeRequest(endpoint);
      final data = response['data'];
      if (data is List) {
        return data.map((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          }
          return <String, dynamic>{};
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching exercises by equipment: $e');
      return [];
    }
  }

  /// Get exercise by ID
  Future<Map<String, dynamic>?> getExerciseById(String exerciseId) async {
    try {
      final endpoint = '/exercises/$exerciseId';
      final response = await _makeRequest(endpoint);
      final data = response['data'];
      if (data is List && data.isNotEmpty) {
        final firstItem = data[0];
        if (firstItem is Map) {
          return Map<String, dynamic>.from(firstItem);
        }
      } else if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e) {
      print('Error fetching exercise by ID: $e');
      return null;
    }
  }

  /// Get image URL from exercise data
  static String? getImageUrl(Map<String, dynamic> exercise) {
    if (exercise['imageUrl'] != null) {
      final imageUrl = exercise['imageUrl'].toString();
      if (imageUrl.startsWith('http')) {
        return imageUrl;
      }
      return 'https://cdn.exercisedb.dev/images/$imageUrl';
    }
    if (exercise['image'] != null) {
      final image = exercise['image'].toString();
      if (image.startsWith('http')) {
        return image;
      }
      return 'https://cdn.exercisedb.dev/images/$image';
    }
    return null;
  }

  /// Get video URL from exercise data
  static String? getVideoUrl(Map<String, dynamic> exercise) {
    if (exercise['videoUrl'] != null) {
      final videoUrl = exercise['videoUrl'].toString();
      if (videoUrl.startsWith('http')) {
        return videoUrl;
      }
      return 'https://cdn.exercisedb.dev/videos/$videoUrl';
    }
    if (exercise['video'] != null) {
      final video = exercise['video'].toString();
      if (video.startsWith('http')) {
        return video;
      }
      return 'https://cdn.exercisedb.dev/videos/$video';
    }
    return null;
  }
}
