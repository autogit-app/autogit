import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';

/// A feature-rich code field with find bar and word wrap.
class CodeEditorField extends StatefulWidget {
  const CodeEditorField({
    super.key,
    required this.controller,
    this.gutterStyle = const GutterStyle(showLineNumbers: true),
    this.minLines,
    this.readOnly = false,
    this.showFindBar = true,
    this.initialWordWrap = false,
  });

  final CodeController controller;
  final GutterStyle gutterStyle;
  final int? minLines;
  final bool readOnly;
  final bool showFindBar;
  final bool initialWordWrap;

  @override
  State<CodeEditorField> createState() => _CodeEditorFieldState();
}

class _CodeEditorFieldState extends State<CodeEditorField> {
  final TextEditingController _findController = TextEditingController();
  final FocusNode _findFocusNode = FocusNode();
  bool _showFind = false;
  bool _wordWrap = false;
  bool _caseSensitive = false;
  int _currentFindIndex = -1;
  List<int> _findOffsets = [];

  @override
  void initState() {
    super.initState();
    _wordWrap = widget.initialWordWrap;
  }

  @override
  void dispose() {
    _findController.dispose();
    _findFocusNode.dispose();
    super.dispose();
  }

  void _updateFindOffsets() {
    final text = widget.controller.fullText;
    final search = _caseSensitive
        ? _findController.text
        : _findController.text.toLowerCase();
    if (search.isEmpty) {
      _findOffsets = [];
      _currentFindIndex = -1;
      return;
    }
    final offsets = <int>[];
    final textLower = _caseSensitive ? text : text.toLowerCase();
    int i = 0;
    while (true) {
      final idx = textLower.indexOf(search, i);
      if (idx < 0) break;
      offsets.add(idx);
      i = idx + 1;
    }
    _findOffsets = offsets;
    if (_currentFindIndex >= offsets.length)
      _currentFindIndex = offsets.isEmpty ? -1 : 0;
  }

  void _findNext() {
    _updateFindOffsets();
    if (_findOffsets.isEmpty) return;
    _currentFindIndex = (_currentFindIndex + 1) % _findOffsets.length;
    _selectCurrentFind();
  }

  void _findPrevious() {
    _updateFindOffsets();
    if (_findOffsets.isEmpty) return;
    _currentFindIndex = _currentFindIndex <= 0
        ? _findOffsets.length - 1
        : _currentFindIndex - 1;
    _selectCurrentFind();
  }

  void _selectCurrentFind() {
    if (_currentFindIndex < 0 || _currentFindIndex >= _findOffsets.length)
      return;
    final start = _findOffsets[_currentFindIndex];
    final len = _findController.text.length;
    widget.controller.selection = TextSelection(
      baseOffset: start,
      extentOffset: start + len,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showFindBar) ...[
          Row(
            children: [
              IconButton(
                icon: Icon(_showFind ? Icons.find_replace : Icons.search),
                tooltip: _showFind ? 'Hide find' : 'Find in file',
                onPressed: () => setState(() => _showFind = !_showFind),
              ),
              IconButton(
                icon: Icon(_wordWrap ? Icons.wrap_text : Icons.wrap_text),
                tooltip: _wordWrap ? 'Disable word wrap' : 'Enable word wrap',
                onPressed: () => setState(() => _wordWrap = !_wordWrap),
              ),
              if (_showFind) ...[
                Expanded(
                  child: TextField(
                    controller: _findController,
                    focusNode: _findFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Find',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) => _updateFindOffsets(),
                    onSubmitted: (_) => _findNext(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up),
                  tooltip: 'Previous',
                  onPressed: _findOffsets.isEmpty ? null : _findPrevious,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down),
                  tooltip: 'Next',
                  onPressed: _findOffsets.isEmpty ? null : _findNext,
                ),
                IconButton(
                  icon: const Icon(Icons.text_fields),
                  tooltip: _caseSensitive ? 'Case sensitive' : 'Ignore case',
                  onPressed: () =>
                      setState(() => _caseSensitive = !_caseSensitive),
                ),
              ],
            ],
          ),
        ],
        Expanded(
          child: SingleChildScrollView(
            child: CodeField(
              controller: widget.controller,
              gutterStyle: widget.gutterStyle,
              readOnly: widget.readOnly,
              textStyle: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
