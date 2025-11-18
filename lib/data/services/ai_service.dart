import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AIService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  static const String _openaiApiKeyKey = 'openai_api_key';
  static const String _openaiBaseUrl = 'https://api.openai.com/v1';

  /// Initialize Remote Config
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      print('Warning: Failed to initialize Remote Config: $e');
    }
  }

  /// Get OpenAI API key from Remote Config or secure storage
  Future<String?> _getApiKey() async {
    // First try secure storage (for local development/testing)
    final storedKey = await _secureStorage.read(key: _openaiApiKeyKey);
    if (storedKey != null && storedKey.isNotEmpty) {
      return storedKey;
    }

    // Then try Remote Config
    try {
      await _remoteConfig.fetchAndActivate();
      final remoteKey = _remoteConfig.getString(_openaiApiKeyKey);
      if (remoteKey.isNotEmpty) {
        return remoteKey;
      }
    } catch (e) {
      print('Error fetching API key from Remote Config: $e');
    }

    return null;
  }

  /// Invoke OpenAI LLM (ChatGPT) for text generation
  /// Returns the generated content as a Map or String
  Future<dynamic> invokeLLM({
    required String prompt,
    String? systemPrompt,
    Map<String, dynamic>? responseJsonSchema,
    String model = 'gpt-4o-mini',
    double temperature = 0.7,
  }) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'OpenAI API key is missing. Please configure it in Firebase Remote Config '
        'or set it in secure storage.',
      );
    }

    try {
      final messages = <Map<String, String>>[];
      
      // Add system prompt if provided or if JSON schema is required
      if (systemPrompt != null) {
        messages.add({'role': 'system', 'content': systemPrompt});
      } else if (responseJsonSchema != null) {
        messages.add({
          'role': 'system',
          'content': 'You are a helpful assistant that returns responses in JSON format only. '
              'Always use English keys in the JSON object. However, ALL content values must be in Hebrew if the user requests Hebrew content. '
              'Return ONLY valid JSON, no additional text before or after.',
        });
      }

      // Add user prompt
      messages.add({'role': 'user', 'content': prompt});

      final requestBody = {
        'model': model,
        'messages': messages,
        'temperature': temperature,
      };

      // Add response format if JSON schema is provided
      if (responseJsonSchema != null) {
        requestBody['response_format'] = {'type': 'json_object'};
        // Add schema instructions to the prompt
        final schemaPrompt = '\n\nReturn the response in JSON format matching this schema: ${jsonEncode(responseJsonSchema)}';
        messages.last['content'] = messages.last['content']! + schemaPrompt;
      }

      final response = await http.post(
        Uri.parse('$_openaiBaseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'OpenAI API error: ${response.statusCode}. '
          '${errorData['error']?['message'] ?? 'Unknown error'}',
        );
      }

      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'];

      if (content == null) {
        throw Exception('No content in OpenAI response');
      }

      // If JSON schema was requested, parse the JSON response
      if (responseJsonSchema != null) {
        try {
          return jsonDecode(content);
        } catch (e) {
          // If parsing fails, try to extract JSON from the response
          final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
          if (jsonMatch != null) {
            return jsonDecode(jsonMatch.group(0)!);
          }
          throw Exception('Failed to parse JSON response: $e');
        }
      }

      return content;
    } catch (e) {
      throw Exception('Failed to invoke LLM: $e');
    }
  }

  /// Generate image using DALL-E
  /// Returns a map with 'url' and 'revised_prompt'
  Future<Map<String, String>> generateImage({
    required String prompt,
    String model = 'dall-e-3',
    String size = '1024x1024',
    String quality = 'standard', // 'standard' or 'hd' for dall-e-3
  }) async {
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'OpenAI API key is missing. Please configure it in Firebase Remote Config '
        'or set it in secure storage.',
      );
    }

    try {
      // Validate size for DALL-E 3
      final validSizes = model == 'dall-e-3'
          ? ['1024x1024', '1792x1024', '1024x1792']
          : ['256x256', '512x512', '1024x1024'];
      
      final finalSize = validSizes.contains(size) ? size : '1024x1024';

      final requestBody = {
        'model': model,
        'prompt': prompt,
        'size': finalSize,
        'quality': quality,
        'response_format': 'url',
        'n': 1,
      };

      final response = await http.post(
        Uri.parse('$_openaiBaseUrl/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'DALL-E API error: ${response.statusCode}. '
          '${errorData['error']?['message'] ?? 'Unknown error'}',
        );
      }

      final data = jsonDecode(response.body);
      final imageData = data['data']?[0];

      if (imageData == null) {
        throw Exception('No image data in DALL-E response');
      }

      return {
        'url': imageData['url'] ?? '',
        'revised_prompt': imageData['revised_prompt'] ?? prompt,
      };
    } catch (e) {
      throw Exception('Failed to generate image: $e');
    }
  }

  /// Store API key in secure storage (for development/testing)
  Future<void> setApiKey(String apiKey) async {
    await _secureStorage.write(key: _openaiApiKeyKey, value: apiKey);
  }

  /// Clear stored API key
  Future<void> clearApiKey() async {
    await _secureStorage.delete(key: _openaiApiKeyKey);
  }
}

