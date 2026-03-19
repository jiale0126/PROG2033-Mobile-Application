import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:firebase_vertexai/firebase_vertexai.dart';

class AiService {
  static Future<Uint8List?> generatePoster(
    String theme,
    String location,
    double budget,
  ) async {
    const String apiUrl =
        'https://router.huggingface.co/hf-inference/models/stabilityai/stable-diffusion-xl-base-1.0';

    const String hfToken = ''; //API KEY HERE

    final prompt =
        "A professional typography poster design for a university event. Bold text saying '$theme'. Subtitle text saying 'Location: $location'. High quality graphic design, clear text.";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $hfToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"inputs": prompt}),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('HF API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print("Image Generation Error: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> generatePlanning(
    String theme,
    double duration,
    double budget,
    int participants,
    String location,
  ) async {
    final model = FirebaseVertexAI.instance.generativeModel(
      model: 'gemini-2.5-flash',

      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    final prompt =
        """
      You are an expert campus event planner. Create a planning suggestion for this event:
      Theme: $theme
      Duration: $duration hours
      Budget: RM $budget
      Participants: $participants
      Location: $location

      Return ONLY a JSON object with this exact structure:
      {
        "activities": ["activity 1", "activity 2"],
        "logistics": "Logistics details here",
        "catering": "Catering suggestions here"
      }
    """;

    try {
      final response = await model.generateContent([Content.text(prompt)]);

      String jsonString = response.text ?? '{}';

      jsonString = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      return jsonDecode(jsonString);
    } catch (e) {
      print("AI Planning Error: $e");

      return {
        "activities": [
          "Failed to generate activities. Please check your connection.",
        ],
        "logistics": "Error connecting to AI.",
        "catering": "Error connecting to AI.",
      };
    }
  }
}
