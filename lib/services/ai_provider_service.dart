import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../utils/app_config.dart';

/// Unified AI provider that supports Gemini and Groq with automatic
/// failover when quota / rate limits are reached on either provider.
class AIProviderService {
  AIProvider _currentProvider = AppConfig.activeProvider;
  String? _lastSystemPrompt;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 25),
  ));

  /// Optional listener notified when provider switches automatically
  void Function(AIProvider newProvider, String reason)? onProviderSwitched;

  AIProvider get currentProvider => _currentProvider;
  String get providerName =>
      _currentProvider == AIProvider.groq ? 'Groq (Llama)' : 'Gemini';

  /// Initialize the active provider
  Future<void> initialize({String? systemPrompt}) async {
    _lastSystemPrompt = systemPrompt;
    print(' [AIProviderService] Initialized with primary provider: $providerName');
  }

  /// Reset session to default provider and update system prompt
  void resetSession({String? systemPrompt}) {
    _lastSystemPrompt = systemPrompt;
    _currentProvider = AppConfig.activeProvider;
    print(' [AIProviderService] Session reset. Active provider: $providerName');
  }

  /// Switch the active provider and log the transition
  void _switchProvider(AIProvider newProvider, String reason) {
    final oldName = providerName;
    _currentProvider = newProvider;
    print('⚠️ [AIProviderService] $reason. Seamlessly switching from $oldName to $providerName.');
    onProviderSwitched?.call(newProvider, reason);
  }

  AIProvider _getAlternative(AIProvider provider) {
    return provider == AIProvider.gemini ? AIProvider.groq : AIProvider.gemini;
  }

  /// Check if an error or status code is related to quota, rate limits, or transient unavailability
  bool _isQuotaOrTransientError(dynamic error, [int? statusCode, String? body]) {
    if (statusCode == 429 || statusCode == 402 || statusCode == 503 || statusCode == 500) {
      return true;
    }
    final text = '${error ?? ''} ${body ?? ''}'.toLowerCase();
    return text.contains('429') ||
        text.contains('quota') ||
        text.contains('resource_exhausted') ||
        text.contains('rate_limit') ||
        text.contains('rate limit') ||
        text.contains('tokens per minute') ||
        text.contains('requests per minute') ||
        text.contains('requests per day') ||
        text.contains('too many requests') ||
        text.contains('exceeded') ||
        text.contains('capacity') ||
        text.contains('overloaded') ||
        text.contains('unavailable');
  }

  /// Send a message with full history and system prompt context.
  /// If the current provider hits quota limits or fails, it automatically
  /// transfers the full context (situation, safety officer directives, and history)
  /// to the fallback provider and executes immediately.
  Future<String?> sendMessage(
    String message, {
    List<Map<String, String>> history = const [],
    String? systemPrompt,
  }) async {
    final effectiveSystemPrompt = systemPrompt ?? _lastSystemPrompt;
    if (effectiveSystemPrompt != null) {
      _lastSystemPrompt = effectiveSystemPrompt;
    }

    final primary = _currentProvider;
    final fallback = _getAlternative(primary);

    // 1. Attempt with current provider
    try {
      final response = await _executeSendMessage(
        primary,
        message,
        history: history,
        systemPrompt: effectiveSystemPrompt,
      );
      if (response != null && response.trim().isNotEmpty) {
        return response.trim();
      }
      throw Exception('Empty response from ${primary.name}');
    } catch (e) {
      final isQuota = _isQuotaOrTransientError(e);
      final reason = isQuota
          ? 'Quota / Rate Limit reached on ${primary.name}'
          : 'Error on ${primary.name} ($e)';

      print(' [AIProviderService] $reason');
      _switchProvider(fallback, reason);

      // 2. Immediate failover to fallback with identical conversation context
      try {
        print(' [AIProviderService] Replaying situation & chat history (${history.length} turns) to $providerName...');
        final fallbackResponse = await _executeSendMessage(
          fallback,
          message,
          history: history,
          systemPrompt: effectiveSystemPrompt,
        );
        if (fallbackResponse != null && fallbackResponse.trim().isNotEmpty) {
          print(' [AIProviderService] Failover response received successfully from $providerName!');
          return fallbackResponse.trim();
        }
      } catch (fallbackError) {
        print('❌ [AIProviderService] Fallback to $providerName also failed: $fallbackError');
      }
      return null;
    }
  }

  /// One-shot generation with automatic failover
  Future<String?> generateContent(String prompt) async {
    final primary = _currentProvider;
    final fallback = _getAlternative(primary);

    try {
      final response = await _executeGenerateContent(primary, prompt);
      if (response != null && response.trim().isNotEmpty) {
        return response.trim();
      }
      throw Exception('Empty one-shot response from ${primary.name}');
    } catch (e) {
      final reason = 'Quota or error on ${primary.name} ($e)';
      _switchProvider(fallback, reason);

      try {
        final fallbackResponse = await _executeGenerateContent(fallback, prompt);
        if (fallbackResponse != null && fallbackResponse.trim().isNotEmpty) {
          return fallbackResponse.trim();
        }
      } catch (e2) {
        print('❌ [AIProviderService] One-shot fallback failed on $providerName: $e2');
      }
      return null;
    }
  }

  Future<String?> _executeSendMessage(
    AIProvider provider,
    String message, {
    required List<Map<String, String>> history,
    String? systemPrompt,
  }) async {
    if (provider == AIProvider.gemini) {
      return await _sendGeminiMessage(message, history: history, systemPrompt: systemPrompt);
    } else {
      return await _sendGroqMessage(message, history: history, systemPrompt: systemPrompt);
    }
  }

  Future<String?> _executeGenerateContent(AIProvider provider, String prompt) async {
    if (provider == AIProvider.gemini) {
      final model = GenerativeModel(
        model: AppConfig.geminiModel,
        apiKey: AppConfig.geminiApiKey,
      );
      final response = await model.generateContent([Content.text(prompt)]);
      return response.text;
    } else {
      return await _sendGroqMessage(prompt, history: const []);
    }
  }

  /// Gemini handler: sends full conversation history and system instructions
  Future<String?> _sendGeminiMessage(
    String message, {
    required List<Map<String, String>> history,
    String? systemPrompt,
  }) async {
    // Combine history and current message without duplicate
    final fullMessages = <Map<String, String>>[];
    if (history.isNotEmpty && history.last['content'] == message) {
      fullMessages.addAll(history);
    } else {
      fullMessages.addAll(history);
      fullMessages.add({'role': 'user', 'content': message});
    }

    final contents = _buildGeminiContents(fullMessages);

    final model = GenerativeModel(
      model: AppConfig.geminiModel,
      apiKey: AppConfig.geminiApiKey,
      systemInstruction: (systemPrompt != null && systemPrompt.trim().isNotEmpty)
          ? Content.system(systemPrompt)
          : null,
      generationConfig: GenerationConfig(
        temperature: 0.2,
        maxOutputTokens: 1024,
      ),
    );

    final response = await model.generateContent(contents);
    return response.text;
  }

  /// Builds valid alternating Gemini Content items from the unified history
  List<Content> _buildGeminiContents(List<Map<String, String>> messages) {
    final contents = <Content>[];
    String? currentRole;
    final currentParts = <Part>[];

    for (final msg in messages) {
      final rawRole = msg['role'] ?? 'user';
      final role = (rawRole == 'assistant' || rawRole == 'model') ? 'model' : 'user';
      final text = msg['content']?.trim() ?? '';
      if (text.isEmpty) continue;

      if (currentRole == role) {
        currentParts.add(TextPart(text));
      } else {
        if (currentParts.isNotEmpty && currentRole != null) {
          contents.add(Content(currentRole, List.from(currentParts)));
          currentParts.clear();
        }
        currentRole = role;
        currentParts.add(TextPart(text));
      }
    }

    if (currentParts.isNotEmpty && currentRole != null) {
      contents.add(Content(currentRole, List.from(currentParts)));
    }

    // Gemini requires the conversation to start with a 'user' turn
    if (contents.isNotEmpty && contents.first.role != 'user') {
      contents.insert(0, Content('user', [TextPart('Urgence en cours.')]));
    }

    // Gemini requires the final turn to be 'user' for generateContent
    if (contents.isNotEmpty && contents.last.role != 'user') {
      contents.add(Content('user', [TextPart('Que dois-je faire maintenant ?')]));
    }

    return contents;
  }

  /// Groq handler: sends full conversation history and system prompt via OpenAI-compatible API
  Future<String?> _sendGroqMessage(
    String message, {
    required List<Map<String, String>> history,
    String? systemPrompt,
  }) async {
    final messages = <Map<String, String>>[];

    if (systemPrompt != null && systemPrompt.trim().isNotEmpty) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    if (history.isNotEmpty && history.last['content'] == message) {
      messages.addAll(history);
    } else {
      messages.addAll(history);
      messages.add({'role': 'user', 'content': message});
    }

    try {
      final response = await _dio.post(
        '${AppConfig.groqBaseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${AppConfig.groqApiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': AppConfig.groqModel,
          'messages': messages,
          'max_tokens': 1024,
          'temperature': 0.2,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        final choice = data['choices']?[0]?['message'];
        final content = choice?['content'] as String?;
        return content;
      } else {
        throw Exception('Groq API HTTP ${response.statusCode}: ${response.data}');
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? e.message;
      throw Exception('Groq API error [$status]: $body');
    }
  }
}
