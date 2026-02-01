import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/yaml.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/markdown.dart';
import 'package:highlight/languages/plaintext.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:autogit/features/auth/providers/auth_provider.dart';
import 'package:autogit/features/repos/data/github_contents_api.dart';

/// Map file extension to highlight language.
dynamic _languageForFilename(String filename) {
  final ext = filename.contains('.')
      ? filename.split('.').last.toLowerCase()
      : '';
  switch (ext) {
    case 'dart':
      return dart;
    case 'json':
      return json;
    case 'yaml':
    case 'yml':
      return yaml;
    case 'py':
      return python;
    case 'js':
    case 'ts':
    case 'jsx':
    case 'tsx':
      return javascript;
    case 'md':
      return markdown;
    case 'html':
    case 'htm':
      return plaintext;
    case 'css':
      return plaintext;
    default:
      return plaintext;
  }
}

bool _isPreviewable(String path) {
  final ext = path.contains('.') ? path.split('.').last.toLowerCase() : '';
  return ext == 'html' || ext == 'htm';
}

class GithubFileEditorScreen extends ConsumerStatefulWidget {
  const GithubFileEditorScreen({
    super.key,
    required this.owner,
    required this.repo,
    required this.path,
  });

  final String owner;
  final String repo;
  final String path;

  @override
  ConsumerState<GithubFileEditorScreen> createState() =>
      _GithubFileEditorScreenState();
}

class _GithubFileEditorScreenState
    extends ConsumerState<GithubFileEditorScreen> {
  CodeController? _controller;
  String? _error;
  bool _loading = true;
  String? _sha;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = ref.read(githubTokenProvider);
    try {
      final file = await GitHubContentsApi.instance.getFile(
        owner: widget.owner,
        repo: widget.repo,
        path: widget.path,
        token: token,
      );
      if (!mounted) return;
      _sha = file.sha;
      _controller = CodeController(
        text: file.content,
        language: _languageForFilename(widget.path),
      );
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        final errStr = e.toString();
        if (errStr.contains('404') || errStr.contains('Not Found')) {
          _sha = null;
          _controller = CodeController(
            text: '',
            language: _languageForFilename(widget.path),
          );
          setState(() {
            _loading = false;
            _error = null;
          });
        } else {
          setState(() {
            _loading = false;
            _error = errStr;
          });
        }
      }
    }
  }

  Future<void> _save() async {
    if (_controller == null) return;
    setState(() => _saving = true);
    final token = ref.read(githubTokenProvider);
    try {
      if (_sha != null) {
        await GitHubContentsApi.instance.updateFile(
          owner: widget.owner,
          repo: widget.repo,
          path: widget.path,
          content: _controller!.fullText,
          message: 'Update ${widget.path.split('/').last}',
          sha: _sha!,
          token: token,
        );
      } else {
        await GitHubContentsApi.instance.createFile(
          owner: widget.owner,
          repo: widget.repo,
          path: widget.path,
          content: _controller!.fullText,
          message: 'Add ${widget.path.split('/').last}',
          token: token,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Saved')));
      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openPreview() {
    if (_controller == null) return;
    final html = _controller!.fullText;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 1,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            AppBar(
              title: const Text('Preview'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: WebViewWidget(
                controller: WebViewController()
                  ..setJavaScriptMode(JavaScriptMode.unrestricted)
                  ..loadHtmlString(html),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.path.split('/').last)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.path.split('/').last)),
        body: Center(child: Text(_error!)),
      );
    }
    if (_controller == null) return const SizedBox.shrink();

    final canPreview = _isPreviewable(widget.path);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.path.split('/').last),
        actions: [
          if (canPreview)
            IconButton(
              icon: const Icon(Icons.preview),
              tooltip: 'Preview in browser',
              onPressed: _openPreview,
            ),
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: 'Save',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: CodeTheme(
        data: CodeThemeData(styles: githubTheme),
        child: SingleChildScrollView(
          child: CodeField(
            controller: _controller!,
            gutterStyle: GutterStyle(showLineNumbers: true),
          ),
        ),
      ),
    );
  }
}
