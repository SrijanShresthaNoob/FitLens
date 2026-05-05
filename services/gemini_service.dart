// lib/services/gemini_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/food_entry.dart';
import '../utils/constants.dart';

class GeminiService {
  static const String _endpoint =
      '${AppConstants.geminiEndpoint}${AppConstants.geminiModel}:generateContent'
      '?key=${AppConstants.geminiApiKey}';

  static const String _prompt = '''
You are a nutrition expert AI. Analyze this food image and provide accurate nutritional estimates.

Return ONLY valid JSON in this exact format (no markdown, no extra text):
{
  "name": "Food Name",
  "emoji": "🍗",
  "calories": 350,
  "protein": 28.5,
  "carbs": 12.0,
  "fat": 18.0,
  "serving_size": "1 plate (~300g)",
  "confidence": "high"
}

Rules:
- Be specific (e.g. "Grilled Chicken Breast" not just "Chicken")
- Estimate for the visible portion size
- All numbers should be per serving shown
- confidence: "high", "medium", or "low"
- If no food is visible, return: {"error": "No food detected"}
''';

  static Future<FoodEntry> analyzeFood(File imageFile) async {
    // Convert image to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final mimeType = imageFile.path.toLowerCase().endsWith('.png')
        ? 'image/png'
        : 'image/jpeg';

    // Build Gemini request
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            },
          ],
        }
      ],
      'generationConfig': {
        'temperature': 0.1, // Low temp = more consistent output
        'maxOutputTokens': 512,
      },
    });

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Gemini API error: ${response.statusCode}\n${response.body}');
    }

    final decoded = jsonDecode(response.body);
    final text =
        decoded['candidates'][0]['content']['parts'][0]['text'] as String;

    // Clean and parse JSON
    final cleanedText =
        text.trim().replaceAll('```json', '').replaceAll('```', '').trim();

    final Map<String, dynamic> foodData = jsonDecode(cleanedText);

    if (foodData.containsKey('error')) {
      throw Exception(foodData['error']);
    }

    return FoodEntry(
      name: foodData['name'] ?? 'Unknown Food',
      emoji: foodData['emoji'] ?? '🍽️',
      calories: (foodData['calories'] as num).toDouble(),
      protein: (foodData['protein'] as num).toDouble(),
      carbs: (foodData['carbs'] as num).toDouble(),
      fat: (foodData['fat'] as num).toDouble(),
      timestamp: DateTime.now(),
    );
  }
}
