import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyDwfMziEE3i90HY4HT_83XXN7HWojMzg_g';

  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        maxOutputTokens: 150,
      ),
      systemInstruction: Content.system(
        'You are SaveSphere AI, a smart home energy and water management assistant. '
        'You have access to real-time data about the user\'s electricity and water usage. '
        'Always answer in exactly 1-2 clear, concise sentences. '
        'Only answer questions related to energy, electricity, water usage, bills, savings, or home appliances. '
        'If asked anything else, say: "I specialise in energy and water management. How can I help you save today?" '
        'Never use emojis, bullet points, or markdown formatting. '
        'Be friendly, precise, and data-driven.',
      ),
    );
    _chat = _model.startChat();
  }

  /// Sends a user query along with current sensor data to Gemini and returns the AI reply.
  Future<String> ask({
    required String userQuery,
    required Map<String, dynamic> energyContext,
    required Map<String, dynamic> waterContext,
  }) async {
    try {
      final contextPrompt = '''
Current Home Data:
- Total Power: ${energyContext['totalPower'] ?? 'N/A'} W
- Bedroom: ${energyContext['bedroomOn'] == true ? 'ON' : 'OFF'} (${energyContext['bedroomPower'] ?? 0} W)
- Living Room: ${energyContext['livingOn'] == true ? 'ON' : 'OFF'} (${energyContext['livingPower'] ?? 0} W)
- Kitchen: ${energyContext['kitchenOn'] == true ? 'ON' : 'OFF'} (${energyContext['kitchenPower'] ?? 0} W)
- Today\'s Energy Used: ${energyContext['todayKwh'] ?? 'N/A'} kWh
- This Month\'s Energy: ${energyContext['monthKwh'] ?? 'N/A'} kWh
- Estimated Bill: ₹${energyContext['estimatedBill'] ?? 'N/A'}
- Water Tank Level: ${waterContext['tankLevel'] ?? 'N/A'}%
- Water Flow Rate: ${waterContext['flowRate'] ?? 'N/A'} L/min
- Today\'s Water Used: ${waterContext['todayLiters'] ?? 'N/A'} L

User asked: $userQuery
''';

      final response = await _chat.sendMessage(Content.text(contextPrompt));
      final text = response.text?.trim() ?? '';
      return text.isNotEmpty ? text : 'I could not process your request. Please try again.';
    } catch (e) {
      debugPrint('GeminiService error: $e');
      return 'Unable to reach AI service right now. Please check your connection.';
    }
  }

  /// One-shot query without chat history (for simple lookups)
  Future<String> quickAsk(String prompt) async {
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? 'No response received.';
    } catch (e) {
      debugPrint('GeminiService quickAsk error: $e');
      return 'AI service unavailable.';
    }
  }
}
