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
import 'package:flutter_highlight/themes/atom-one-dark.dart';

import 'package:autogit/core/widgets/code_editor_field.dart';
import 'package:autogit/features/repos/data/local_repo_providers.dart';

dynamic _languageForFilename(String filename) {
  final ext =
      filename.contains('.') ? filename.split('.').last.toLowerCase() : '';
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
    default:
      return plaintext;
  }
}

class LocalFileEditorScreen extends ConsumerStatefulWidget {
  const LocalFileEditorScreen({
    super.key,
    required this.repoName,
    required this.path,
  });

  final String repoName;
  final String path;

  @override
  ConsumerState<LocalFileEditorScreen> createState() =>
      _LocalFileEditorScreenState();
}

class _LocalFileEditorScreenState extends ConsumerState<LocalFileEditorScreen> {
  CodeController? _controller;
  String? _error;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) {
      setState(() {
        _error = 'Local git service not ready';
        _loading = false;
      });
      return;
    }
    try {
      final content = await service.readFile(widget.repoName, widget.path);
      if (!mounted) return;
      _controller = CodeController(
        text: content,
        language: _languageForFilename(widget.path),
      );
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _save() async {
    if (_controller == null) return;
    final service = ref.read(localRepoServiceProvider).value;
    if (service == null) return;
    setState(() => _saving = true);
    try {
      await service.writeFile(
          widget.repoName, widget.path, _controller!.fullText);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final codeTheme = isDark ? atomOneDarkTheme : githubTheme;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.path.split('/').last),
        actions: [
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
        data: CodeThemeData(styles: codeTheme),
        child: CodeEditorField(
          controller: _controller!,
          gutterStyle: const GutterStyle(showLineNumbers: true),
          showFindBar: true,
        ),
      ),
    );
  }
}
