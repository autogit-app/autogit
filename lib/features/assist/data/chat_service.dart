import 'dart:convert';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:http/http.dart' as http;

import 'package:autogit/features/settings/logic/ai_settings_providers.dart';

/// Result of sending a message. [gemmaChat] is non-null when using Flutter Gemma (pass back next time).
class ChatServiceResult {
  ChatServiceResult(this.reply, [this.gemmaChat]);
  final String reply;
  final dynamic gemmaChat;
}

/// Sends a chat message to the configured backend and returns the assistant reply.
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  Future<ChatServiceResult> sendMessage({
    required AiBackend backend,
    required String ollamaUrl,
    required String ollamaModel,
    required String apiKey,
    required String openAiModel,
    required String claudeModel,
    required String geminiModel,
    required List<ChatMessage> messages,
    dynamic gemmaChat,
  }) async {
    switch (backend) {
      case AiBackend.flutterGemma:
        return _sendFlutterGemma(messages: messages, existingChat: gemmaChat);
      case AiBackend.ollama:
        final reply = await _sendOllama(
          ollamaUrl: ollamaUrl,
          model: ollamaModel,
          messages: messages,
        );
        return ChatServiceResult(reply);
      case AiBackend.openai:
        final reply = await _sendOpenAi(
          apiKey: apiKey,
          model: openAiModel,
          messages: messages,
        );
        return ChatServiceResult(reply);
      case AiBackend.claude:
        final reply = await _sendClaude(
          apiKey: apiKey,
          model: claudeModel,
          messages: messages,
        );
        return ChatServiceResult(reply);
      case AiBackend.gemini:
        final reply = await _sendGemini(
          apiKey: apiKey,
          model: geminiModel,
          messages: messages,
        );
        return ChatServiceResult(reply);
    }
  }

  Future<ChatServiceResult> _sendFlutterGemma({
    required List<ChatMessage> messages,
    dynamic existingChat,
  }) async {
    try {
      dynamic chat = existingChat;
      if (chat == null) {
        final model = await FlutterGemma.getActiveModel(maxTokens: 2048);
        chat = await model.createChat();
      }
      final lastUser = messages.isNotEmpty ? messages.last : null;
      if (lastUser == null || lastUser.role != 'user') {
        throw Exception('No user message to send.');
      }
      await (chat as dynamic).addQueryChunk(
        Message.text(text: lastUser.content, isUser: true),
      );
      final response = await (chat as dynamic).generateChatResponse();
      String reply = '';
      if (response is TextResponse) {
        reply = response.token;
      }
      return ChatServiceResult(reply.trim(), chat);
    } catch (e) {
      if (e.toString().contains('model') ||
          e.toString().contains('install') ||
          e.toString().contains('active')) {
        throw Exception(
          'No on-device model loaded. Go to Settings > AI / Assistant and download a model (e.g. SmolLM or Gemma 3 270M).',
        );
      }
      rethrow;
    }
  }

  Future<String> _sendOllama({
    required String ollamaUrl,
    required String model,
    required List<ChatMessage> messages,
  }) async {
    final base = ollamaUrl.replaceFirst(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/api/chat');
    final body = {
      'model': model.isEmpty ? 'llama2' : model,
      'messages': messages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList(),
      'stream': false,
    };
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Ollama error: ${response.statusCode} ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final message = json['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String? ?? '';
    return content.trim();
  }

  Future<String> _sendOpenAi({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
  }) async {
    if (apiKey.isEmpty)
      throw Exception(
        'OpenAI API key not set. Configure in Settings > AI / Assistant.',
      );
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final body = {
      'model': model.isEmpty ? 'gpt-4o-mini' : model,
      'messages': messages
          .map((m) => {'role': m.role, 'content': m.content})
          .toList(),
    };
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      final err = response.body;
      throw Exception('OpenAI error: ${response.statusCode} $err');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>?;
    final content =
        (choices?.isNotEmpty == true && choices!.first is Map<String, dynamic>)
        ? (choices.first as Map<String, dynamic>)['message']
                  is Map<String, dynamic>
              ? ((choices.first as Map<String, dynamic>)['message']
                        as Map<String, dynamic>)['content']
                    as String?
              : null
        : null;
    return content?.trim() ?? '';
  }

  Future<String> _sendClaude({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
  }) async {
    if (apiKey.isEmpty)
      throw Exception(
        'Claude API key not set. Configure in Settings > AI / Assistant.',
      );
    final uri = Uri.parse('https://api.anthropic.com/v1/messages');
    final system = messages
        .where((m) => m.role == 'system')
        .map((m) => m.content)
        .join('\n');
    final chatMessages = messages.where((m) => m.role != 'system').toList();
    final body = <String, dynamic>{
      'model': model.isEmpty ? 'claude-3-5-haiku-20241022' : model,
      'max_tokens': 1024,
      'messages': chatMessages
          .map(
            (m) => {
              'role': m.role == 'user' ? 'user' : 'assistant',
              'content': m.content,
            },
          )
          .toList(),
    };
    if (system.isNotEmpty) body['system'] = system;
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Claude error: ${response.statusCode} ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final contentList = json['content'] as List<dynamic>?;
    final text = contentList
        ?.whereType<Map<String, dynamic>>()
        .where((c) => c['type'] == 'text')
        .map((c) => c['text'] as String? ?? '')
        .join('');
    return text?.trim() ?? '';
  }

  Future<String> _sendGemini({
    required String apiKey,
    required String model,
    required List<ChatMessage> messages,
  }) async {
    if (apiKey.isEmpty)
      throw Exception(
        'Gemini API key not set. Configure in Settings > AI / Assistant.',
      );
    final modelName = model.isEmpty ? 'gemini-2.5-flash' : model;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$apiKey',
    );
    final contents = messages
        .map(
          (m) => {
            'role': m.role == 'user' ? 'user' : 'model',
            'parts': [
              {'text': m.content},
            ],
          },
        )
        .toList();
    final body = {'contents': contents};
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Gemini error: ${response.statusCode} ${response.body}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    final content =
        candidates?.isNotEmpty == true &&
            candidates!.first is Map<String, dynamic>
        ? (candidates.first as Map<String, dynamic>)['content']
              as Map<String, dynamic>?
        : null;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts
        ?.whereType<Map<String, dynamic>>()
        .map((p) => p['text'] as String? ?? '')
        .join('');
    return text?.trim() ?? '';
  }
}

class ChatMessage {
  ChatMessage({required this.role, required this.content});
  final String role; // 'user', 'assistant', 'system'
  final String content;
}
