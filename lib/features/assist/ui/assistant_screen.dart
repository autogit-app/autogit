import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:autogit/core/widgets/large_app_bar.dart';
import 'package:autogit/features/assist/data/chat_service.dart';
import 'package:autogit/features/settings/logic/ai_settings_providers.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _messages = <ChatMessage>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = false;
  String? _error;
  dynamic
  _gemmaChat; // Kept when using Flutter Gemma for conversation continuity

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _controller.clear();
      _messages.add(ChatMessage(role: 'user', content: text));
      _loading = true;
      _error = null;
    });
    _scrollToBottom();

    final backend = ref.read(aiBackendProvider);
    final ollamaUrl = ref.read(aiOllamaUrlProvider);
    final ollamaModel = ref.read(aiOllamaModelProvider);
    final apiKey = ref.read(aiApiKeyProvider);
    final openAiModel = ref.read(aiOpenAiModelProvider);
    final claudeModel = ref.read(aiClaudeModelProvider);
    final geminiModel = ref.read(aiGeminiModelProvider);

    try {
      final result = await ChatService.instance.sendMessage(
        backend: backend,
        ollamaUrl: ollamaUrl,
        ollamaModel: ollamaModel,
        apiKey: apiKey,
        openAiModel: openAiModel,
        claudeModel: claudeModel,
        geminiModel: geminiModel,
        messages: _messages,
        gemmaChat: backend == AiBackend.flutterGemma ? _gemmaChat : null,
      );
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(role: 'assistant', content: result.reply));
          if (result.gemmaChat != null) _gemmaChat = result.gemmaChat;
          _loading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    ref.watch(aiSettingsLoadProvider);

    return Scaffold(
      body: Column(
        children: [
          if (_error != null)
            Material(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _error = null),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                const LargeAppBar(title: 'Assistant'),
                if (_messages.isEmpty && !_loading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 64,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ask anything. Use Settings > AI / Assistant to choose on-device (Flutter Gemma), Ollama (desktop), or remote (ChatGPT, Claude, Gemini). Download a model in Settings for on-device chat on your phone.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        if (index == _messages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Thinking...',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        final msg = _messages[index];
                        final isUser = msg.role == 'user';
                        return Align(
                          alignment: isUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * 0.8,
                            ),
                            child: Text(
                              msg.content,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: isUser
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ),
                        );
                      }, childCount: _messages.length + (_loading ? 1 : 0)),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      maxLines: 4,
                      minLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _loading ? null : _send,
                    icon: const Icon(Icons.send),
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
