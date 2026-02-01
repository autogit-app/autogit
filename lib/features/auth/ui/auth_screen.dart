import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:autogit/features/auth/data/github_auth_service.dart';
import 'package:autogit/features/auth/providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _launchGitHubSignUp() async {
    const url = 'https://github.com/signup';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }

  Future<void> _signInWithGitHub() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final error = await GitHubAuthService.instance.login();
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _isLoading = false;
        _error = error;
      });
      return;
    }
    ref.invalidate(authStateProvider);
    setState(() => _isLoading = false);
    context.go('/onboarding');
  }

  Future<void> _proceedWithoutSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    await GitHubAuthService.instance.proceedWithoutSignIn();
    if (!mounted) return;
    ref.invalidate(authStateProvider);
    setState(() => _isLoading = false);
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Authentication Heading
              Text(
                'Authentication',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),

              // GitHub Login Button
              FilledButton.icon(
                onPressed: _isLoading ? null : _signInWithGitHub,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF24292E),
                  foregroundColor: Colors.white,
                ),
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const FaIcon(FontAwesomeIcons.github, size: 20),
                label: Text(
                  _isLoading ? 'Signing in...' : 'Continue with GitHub',
                ),
              ),
              const SizedBox(height: 16),

              // Don't have an account? Sign Up
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _launchGitHubSignUp,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colorScheme.outlineVariant),
                  foregroundColor: colorScheme.onSurface,
                ),
                icon: const FaIcon(FontAwesomeIcons.github, size: 18),
                label: const Text('Don\'t have an account? Sign Up'),
              ),

              const SizedBox(height: 32),

              // Divider with "or"
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'or',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 24),

              // Proceed without Sign In
              OutlinedButton(
                onPressed: _isLoading ? null : _proceedWithoutSignIn,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colorScheme.outlineVariant),
                  foregroundColor: colorScheme.onSurface,
                ),
                child: const Text('Proceed without Sign In'),
              ),

              const Spacer(),

              // App Info
              Text(
                'AutoGit v1.0.0',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
