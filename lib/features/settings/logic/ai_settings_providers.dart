import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _keyBackend = 'ai_backend';
const _keyOllamaUrl = 'ai_ollama_url';
const _keyOllamaModel = 'ai_ollama_model';
const _keyApiKey = 'ai_api_key';
const _keyOpenAiModel = 'ai_openai_model';
const _keyClaudeModel = 'ai_claude_model';
const _keyGeminiModel = 'ai_gemini_model';
const _keyFlutterGemmaModelUrl = 'ai_flutter_gemma_model_url';

enum AiBackend { flutterGemma, ollama, openai, claude, gemini }

extension AiBackendX on AiBackend {
  String get label {
    switch (this) {
      case AiBackend.flutterGemma:
        return 'Flutter Gemma (on-device)';
      case AiBackend.ollama:
        return 'Ollama (desktop)';
      case AiBackend.openai:
        return 'OpenAI (ChatGPT)';
      case AiBackend.claude:
        return 'Claude (Anthropic)';
      case AiBackend.gemini:
        return 'Gemini (Google)';
    }
  }
}

/// Default: on-device model for phones; users download in Settings.
final aiBackendProvider = StateProvider<AiBackend>(
  (ref) => AiBackend.flutterGemma,
);

final aiOllamaUrlProvider = StateProvider<String>(
  (ref) => 'http://localhost:11434',
);
final aiOllamaModelProvider = StateProvider<String>((ref) => 'llama2');
final aiApiKeyProvider = StateProvider<String>((ref) => '');
final aiOpenAiModelProvider = StateProvider<String>((ref) => 'gpt-4o-mini');
final aiClaudeModelProvider = StateProvider<String>(
  (ref) => 'claude-3-5-haiku-20241022',
);
final aiGeminiModelProvider = StateProvider<String>(
  (ref) => 'gemini-2.5-flash',
);
final aiFlutterGemmaModelUrlProvider = StateProvider<String>((ref) => '');

/// Load AI settings from disk on app start.
final aiSettingsLoadProvider = FutureProvider<void>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final backendIndex = prefs.getInt(_keyBackend);
  if (backendIndex != null &&
      backendIndex >= 0 &&
      backendIndex < AiBackend.values.length) {
    ref.read(aiBackendProvider.notifier).state = AiBackend.values[backendIndex];
  }
  final url = prefs.getString(_keyOllamaUrl);
  if (url != null) ref.read(aiOllamaUrlProvider.notifier).state = url;
  final model = prefs.getString(_keyOllamaModel);
  if (model != null) ref.read(aiOllamaModelProvider.notifier).state = model;
  final key = prefs.getString(_keyApiKey);
  if (key != null) ref.read(aiApiKeyProvider.notifier).state = key;
  final openAiModel = prefs.getString(_keyOpenAiModel);
  if (openAiModel != null)
    ref.read(aiOpenAiModelProvider.notifier).state = openAiModel;
  final claudeModel = prefs.getString(_keyClaudeModel);
  if (claudeModel != null)
    ref.read(aiClaudeModelProvider.notifier).state = claudeModel;
  final geminiModel = prefs.getString(_keyGeminiModel);
  if (geminiModel != null)
    ref.read(aiGeminiModelProvider.notifier).state = geminiModel;
  final gemmaUrl = prefs.getString(_keyFlutterGemmaModelUrl);
  if (gemmaUrl != null)
    ref.read(aiFlutterGemmaModelUrlProvider.notifier).state = gemmaUrl;
});

Future<void> saveAiSettings({
  required AiBackend backend,
  required String ollamaUrl,
  required String ollamaModel,
  required String apiKey,
  required String openAiModel,
  required String claudeModel,
  required String geminiModel,
  required String flutterGemmaModelUrl,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt(_keyBackend, backend.index);
  await prefs.setString(_keyOllamaUrl, ollamaUrl);
  await prefs.setString(_keyOllamaModel, ollamaModel);
  await prefs.setString(_keyApiKey, apiKey);
  await prefs.setString(_keyOpenAiModel, openAiModel);
  await prefs.setString(_keyClaudeModel, claudeModel);
  await prefs.setString(_keyGeminiModel, geminiModel);
  await prefs.setString(_keyFlutterGemmaModelUrl, flutterGemmaModelUrl);
}
