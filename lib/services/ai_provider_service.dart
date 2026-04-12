import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/app_config.dart';

/// Unified AI provider that supports Gemini and Groq
/// Switch providers by changing AppConfig.activeProvider
class AIProviderService {
  // Gemini chat session (only used when provider = gemini)
  GenerativeModel? _geminiModel;
  ChatSession? _geminiSession;

  /// Initialize the active provider
  Future<void> initialize({String? systemPrompt}) async {
    if (AppConfig.activeProvider == AIProvider.gemini) {
      _geminiModel = GenerativeModel(
        model: AppConfig.geminiModel,
        apiKey: AppConfig.geminiApiKey,
        generationConfig: GenerationConfig(
          temperature: 0.2,
          maxOutputTokens: 1024,
        ),
      );
      if (systemPrompt != null) {
        _geminiSession = _geminiModel!.startChat(history: [
          Content.text(systemPrompt),
        ]);
      } else {
        _geminiSession = _geminiModel!.startChat();
      }
    }
    // Groq uses stateless HTTP calls — no init needed
  }

  /// Send a message and get a response from the active provider
  /// [history] is used by Groq to maintain conversation context
  Future<String?> sendMessage(
      String message, {
        List<Map<String, String>> history = const [],
        String? systemPrompt,
      }) async {
    try {
      if (AppConfig.activeProvider == AIProvider.groq) {
        return await _sendGroqMessage(message,
            history: history, systemPrompt: systemPrompt);
      } else {
        return await _sendGeminiMessage(message);
      }
    } catch (e) {
      print('❌ [AIProvider] Error: $e');
      return null;
    }
  }

  /// Generate a one-shot response (no chat history)
  Future<String?> generateContent(String prompt) async {
    try {
      if (AppConfig.activeProvider == AIProvider.groq) {
        return await _sendGroqMessage(prompt);
      } else {
        final model = GenerativeModel(
          model: AppConfig.geminiModel,
          apiKey: AppConfig.geminiApiKey,
        );
        final response = await model.generateContent([Content.text(prompt)]);
        return response.text;
      }
    } catch (e) {
      print('❌ [AIProvider] generateContent error: $e');
      return null;
    }
  }

  Future<String?> _sendGeminiMessage(String message) async {
    if (_geminiSession == null) await initialize();
    final response = await _geminiSession!.sendMessage(Content.text(message));
    return response.text;
  }

  Future<String?> _sendGroqMessage(
      String message, {
        List<Map<String, String>> history = const [],
        String? systemPrompt,
      }) async {
    final messages = <Map<String, String>>[];

    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    // Add conversation history
    messages.addAll(history);

    // Add current message
    messages.add({'role': 'user', 'content': message});

    final response = await http.post(
      Uri.parse('${AppConfig.groqBaseUrl}/chat/completions'),
      headers: {
        'Authorization': 'Bearer ${AppConfig.groqApiKey}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': AppConfig.groqModel,
        'messages': messages,
        'max_tokens': 1024,
        'temperature': 0.2,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String?;
    } else {
      print('❌ Groq error ${response.statusCode}: ${response.body}');
      return null;
    }
  }

  /// Start a fresh chat session (call this when starting a new emergency)
  void resetSession({String? systemPrompt}) {
    if (AppConfig.activeProvider == AIProvider.gemini && _geminiModel != null) {
      if (systemPrompt != null) {
        _geminiSession = _geminiModel!.startChat(history: [
          Content.text(systemPrompt),
        ]);
      } else {
        _geminiSession = _geminiModel!.startChat();
      }
    }
    // Groq is stateless — history is passed per-call, nothing to reset
  }

  String get providerName =>
      AppConfig.activeProvider == AIProvider.groq ? 'Groq (Llama)' : 'Gemini';
}