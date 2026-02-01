import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:autogit/features/auth/providers/auth_provider.dart';
import 'package:autogit/features/repos/data/github_repo_api.dart';

class RepoSettingsScreen extends ConsumerStatefulWidget {
  const RepoSettingsScreen({
    super.key,
    required this.owner,
    required this.repo,
  });

  final String owner;
  final String repo;

  @override
  ConsumerState<RepoSettingsScreen> createState() => _RepoSettingsScreenState();
}

class _RepoSettingsScreenState extends ConsumerState<RepoSettingsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _homepageController = TextEditingController();
  bool _private = false;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _homepageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final token = ref.read(githubTokenProvider);
    try {
      final uri = Uri.parse(
        'https://api.github.com/repos/${widget.owner}/${widget.repo}',
      );
      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'AutoGit',
      };
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final response = await http.get(uri, headers: headers);
      if (response.statusCode != 200) {
        throw Exception('Failed to load repo: ${response.statusCode}');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (mounted) {
        _nameController.text = data['name'] as String? ?? widget.repo;
        _descriptionController.text = data['description'] as String? ?? '';
        _homepageController.text = data['homepage'] as String? ?? '';
        _private = data['private'] as bool? ?? false;
        setState(() {
          _loading = false;
          _error = null;
        });
      }
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
    setState(() => _saving = true);
    final token = ref.read(githubTokenProvider);
    try {
      await updateRepo(
        owner: widget.owner,
        repo: widget.repo,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        private: _private,
        homepage: _homepageController.text.trim().isEmpty
            ? null
            : _homepageController.text.trim(),
        token: token,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings saved')));
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('${widget.owner}/${widget.repo}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Repo settings')),
        body: Center(child: Text('Error: $_error')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repo settings'),
        actions: [
          if (_saving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Repository name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _homepageController,
            decoration: const InputDecoration(
              labelText: 'Homepage URL',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Private'),
            value: _private,
            onChanged: (v) => setState(() => _private = v),
          ),
        ],
      ),
    );
  }
}
