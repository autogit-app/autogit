import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/settings/logic/ai_settings_providers.dart';

/// Example URL – paste any .task or .bin model URL from HuggingFace (e.g. Gemma 3 270M, Qwen).
const String kFlutterGemmaModelUrlHint =
    'https://huggingface.co/.../resolve/main/model.task';

class AiScreen extends ConsumerStatefulWidget {
  const AiScreen({super.key});

  @override
  ConsumerState<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends ConsumerState<AiScreen> {
  late TextEditingController _ollamaUrlController;
  late TextEditingController _ollamaModelController;
  late TextEditingController _apiKeyController;
  late TextEditingController _openAiModelController;
  late TextEditingController _claudeModelController;
  late TextEditingController _geminiModelController;
  late TextEditingController _flutterGemmaUrlController;

  bool _syncedFromProviders = false;
  bool _downloadingModel = false;
  int _downloadProgress = 0;

  @override
  void initState() {
    super.initState();
    _ollamaUrlController = TextEditingController(
      text: 'http://localhost:11434',
    );
    _ollamaModelController = TextEditingController(text: 'llama2');
    _apiKeyController = TextEditingController();
    _openAiModelController = TextEditingController(text: 'gpt-4o-mini');
    _claudeModelController = TextEditingController(
      text: 'claude-3-5-haiku-20241022',
    );
    _geminiModelController = TextEditingController(text: 'gemini-2.5-flash');
    _flutterGemmaUrlController = TextEditingController();
  }

  void _syncFromProviders(WidgetRef ref) {
    if (_syncedFromProviders) return;
    _ollamaUrlController.text = ref.read(aiOllamaUrlProvider);
    _ollamaModelController.text = ref.read(aiOllamaModelProvider);
    _apiKeyController.text = ref.read(aiApiKeyProvider);
    _openAiModelController.text = ref.read(aiOpenAiModelProvider);
    _claudeModelController.text = ref.read(aiClaudeModelProvider);
    _geminiModelController.text = ref.read(aiGeminiModelProvider);
    _flutterGemmaUrlController.text = ref.read(aiFlutterGemmaModelUrlProvider);
    _syncedFromProviders = true;
  }

  @override
  void dispose() {
    _ollamaUrlController.dispose();
    _ollamaModelController.dispose();
    _apiKeyController.dispose();
    _openAiModelController.dispose();
    _claudeModelController.dispose();
    _geminiModelController.dispose();
    _flutterGemmaUrlController.dispose();
    super.dispose();
  }

  Future<void> _downloadFlutterGemmaModel() async {
    final url = _flutterGemmaUrlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a model URL first (e.g. from HuggingFace).'),
        ),
      );
      return;
    }
    if (_downloadingModel) return;
    setState(() {
      _downloadingModel = true;
      _downloadProgress = 0;
    });
    try {
      await FlutterGemma.installModel(
        modelType: ModelType.general,
      ).fromNetwork(url).withProgress((progress) {
        if (mounted) setState(() => _downloadProgress = progress);
      }).install();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Model downloaded. You can use the Assistant now.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _downloadingModel = false);
    }
  }

  Future<void> _save() async {
    final backend = ref.read(aiBackendProvider);
    ref.read(aiOllamaUrlProvider.notifier).state = _ollamaUrlController.text
        .trim();
    ref.read(aiOllamaModelProvider.notifier).state = _ollamaModelController.text
        .trim();
    ref.read(aiApiKeyProvider.notifier).state = _apiKeyController.text.trim();
    ref.read(aiOpenAiModelProvider.notifier).state = _openAiModelController.text
        .trim();
    ref.read(aiClaudeModelProvider.notifier).state = _claudeModelController.text
        .trim();
    ref.read(aiGeminiModelProvider.notifier).state = _geminiModelController.text
        .trim();
    ref.read(aiFlutterGemmaModelUrlProvider.notifier).state =
        _flutterGemmaUrlController.text.trim();
    await saveAiSettings(
      backend: backend,
      ollamaUrl: _ollamaUrlController.text.trim(),
      ollamaModel: _ollamaModelController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      openAiModel: _openAiModelController.text.trim(),
      claudeModel: _claudeModelController.text.trim(),
      geminiModel: _geminiModelController.text.trim(),
      flutterGemmaModelUrl: _flutterGemmaUrlController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI settings saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    ref.watch(aiSettingsLoadProvider).whenData((_) => _syncFromProviders(ref));
    final backend = ref.watch(aiBackendProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const LargeAppBar(title: 'AI / Assistant'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Backend',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AiBackend>(
                    value: backend,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: AiBackend.values
                        .map(
                          (e) =>
                              DropdownMenuItem(value: e, child: Text(e.label)),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null)
                        ref.read(aiBackendProvider.notifier).state = v;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (backend == AiBackend.flutterGemma) ...[
                    Text(
                      'On-device model (phones & tablets)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Paste a model URL from HuggingFace (e.g. Gemma 3 270M, Qwen; .task or .bin). Then tap Download.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _flutterGemmaUrlController,
                      decoration: InputDecoration(
                        labelText: 'Model URL',
                        hintText: kFlutterGemmaModelUrlHint,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    if (_downloadingModel)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          LinearProgressIndicator(
                            value: _downloadProgress / 100,
                          ),
                          const SizedBox(height: 8),
                          Text('Downloading... $_downloadProgress%'),
                        ],
                      )
                    else
                      FilledButton.icon(
                        onPressed: _downloadFlutterGemmaModel,
                        icon: const Icon(Icons.download),
                        label: const Text('Download model'),
                      ),
                  ] else if (backend == AiBackend.ollama) ...[
                    Text(
                      'Ollama (desktop only)',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Install Ollama on your PC/Mac, then run: ollama pull <model>. Use the URL and model name below. Does not work on phones.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ollamaUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Ollama URL',
                        hintText: 'http://localhost:11434',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ollamaModelController,
                      decoration: const InputDecoration(
                        labelText: 'Model name',
                        hintText: 'llama2, mistral, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Remote API (${backend.label})',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      backend == AiBackend.openai
                          ? 'Get your API key from platform.openai.com'
                          : backend == AiBackend.claude
                          ? 'Get your API key from console.anthropic.com'
                          : 'Get your API key from aistudio.google.com',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'API key',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: backend == AiBackend.openai
                          ? _openAiModelController
                          : backend == AiBackend.claude
                          ? _claudeModelController
                          : _geminiModelController,
                      decoration: InputDecoration(
                        labelText: 'Model name',
                        hintText: backend == AiBackend.openai
                            ? 'gpt-4o-mini, gpt-4o, etc.'
                            : backend == AiBackend.claude
                            ? 'claude-3-5-haiku-20241022, etc.'
                            : 'gemini-2.5-flash, gemini-2.0-flash, etc.',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('Save settings'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
