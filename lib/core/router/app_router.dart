import 'package:go_router/go_router.dart';
import 'package:autogit/features/assist/ui/assistant_screen.dart';
import 'package:autogit/features/auth/data/auth_state.dart';
import 'package:autogit/features/auth/ui/auth_screen.dart';
import 'package:autogit/features/home/ui/home_screen.dart';
import 'package:autogit/features/home/ui/notifications_screen.dart';
import 'package:autogit/features/home/ui/starred_screen.dart';
import 'package:autogit/features/home/ui/watched_screen.dart';
import 'package:autogit/features/home/ui/issues_screen.dart';
import 'package:autogit/features/home/ui/pull_requests_screen.dart';
import 'package:autogit/features/home/ui/sites_screen.dart';
import 'package:autogit/features/home/ui/create_site_screen.dart';
import 'package:autogit/features/home/ui/create_code_repo_screen.dart';
import 'package:autogit/features/home/ui/projects_screen.dart';
import 'package:autogit/features/home/ui/discussions_screen.dart';
import 'package:autogit/features/onboarding/ui/onboarding_screen.dart';
import 'package:autogit/features/repos/ui/local/local_repos_screen.dart';
import 'package:autogit/features/repos/ui/local/local_repository_screen.dart';
import 'package:autogit/features/repos/ui/github/github_repos_screen.dart';
import 'package:autogit/features/repos/ui/github/github_file_editor_screen.dart';
import 'package:autogit/features/repos/ui/github/github_repository_screen.dart';
import 'package:autogit/features/repos/ui/github/repo_settings_screen.dart';
import 'package:autogit/features/home/ui/widgets/home_fab.dart';
import 'package:autogit/core/widgets/scaffold.dart';
import 'package:autogit/features/search/ui/search_screen.dart';
import 'package:autogit/features/search/ui/user_profile_screen.dart';
import 'package:autogit/features/search/ui/user_repos_screen.dart';
import 'package:autogit/features/home/ui/issue_detail_screen.dart';
import 'package:autogit/features/home/ui/pr_detail_screen.dart';
import 'package:autogit/features/profile/ui/profile_screen.dart';
import 'package:autogit/features/settings/ui/sections/about_screen.dart';
import 'package:autogit/features/settings/ui/sections/ai_screen.dart';
import 'package:autogit/features/settings/ui/sections/appearance_screen.dart';
import 'package:autogit/features/settings/ui/sections/statistics_screen.dart';
import 'package:autogit/features/settings/ui/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AuthState.isAuthenticated ? '/home' : '/auth',
  routes: [
    // Redirect root based on auth
    GoRoute(
      path: '/',
      redirect: (context, state) =>
          AuthState.isAuthenticated ? '/home' : '/auth',
    ),

    // Auth & Onboarding
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // User profile (in-app, no redirect to github.com)
    GoRoute(
      path: '/user/:login',
      builder: (context, state) =>
          UserProfileScreen(login: state.pathParameters['login']!),
      routes: [
        GoRoute(
          path: 'repos',
          builder: (context, state) =>
              UserReposScreen(login: state.pathParameters['login']!),
        ),
      ],
    ),

    // Main Shell with Bottom Navigation
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        final currentPath = state.uri.path;

        return ScaffoldWithNavBar(
          navigationShell: navigationShell,
          floatingActionButton: switch (currentPath) {
            '/home' => const HomeFab(),
            '/home/local' => const HomeFab(),
            '/home/github' => const HomeFab(),
            '/home/gitlab' => const HomeFab(),
            _ => null,
          },
        );
      },
      branches: [
        // ==== HOME BRANCH ====
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/home/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
            GoRoute(
              path: '/home/starred',
              builder: (context, state) => const StarredScreen(),
            ),
            GoRoute(
              path: '/home/watched',
              builder: (context, state) => const WatchedScreen(),
            ),
            GoRoute(
              path: '/home/issues',
              builder: (context, state) => const IssuesScreen(),
            ),
            GoRoute(
              path: '/home/pull-requests',
              builder: (context, state) => const PullRequestsScreen(),
            ),
            GoRoute(
              path: '/home/sites',
              builder: (context, state) => const SitesScreen(),
            ),
            GoRoute(
              path: '/home/create-site',
              builder: (context, state) => const CreateSiteScreen(),
            ),
            GoRoute(
              path: '/home/create-code-repo',
              builder: (context, state) => const CreateCodeRepoScreen(),
            ),
            GoRoute(
              path: '/home/projects',
              builder: (context, state) => const ProjectsScreen(),
            ),
            GoRoute(
              path: '/home/discussions',
              builder: (context, state) => const DiscussionsScreen(),
            ),
            GoRoute(
              path: '/home/issue/:owner/:repo/:number',
              builder: (context, state) => IssueDetailScreen(
                owner: state.pathParameters['owner']!,
                repo: state.pathParameters['repo']!,
                number: int.parse(state.pathParameters['number'] ?? '0'),
              ),
            ),
            GoRoute(
              path: '/home/pr/:owner/:repo/:number',
              builder: (context, state) => PRDetailScreen(
                owner: state.pathParameters['owner']!,
                repo: state.pathParameters['repo']!,
                number: int.parse(state.pathParameters['number'] ?? '0'),
              ),
            ),
            GoRoute(
              path: '/home/local',
              builder: (context, state) => const LocalReposScreen(),
            ),
            GoRoute(
              path: '/home/github',
              builder: (context, state) => const GithubReposScreen(),
            ),
            GoRoute(
              path: '/home/local/:repo',
              builder: (context, state) =>
                  LocalRepositoryScreen(param: state.pathParameters['repo']!),
            ),
            // GitHub repo: /home/github/:owner/:repo (search + my repos)
            GoRoute(
              path: '/home/github/:owner/:repo',
              builder: (context, state) => GithubRepositoryScreen(
                owner: state.pathParameters['owner']!,
                repo: state.pathParameters['repo']!,
              ),
              routes: [
                GoRoute(
                  path: 'file',
                  builder: (context, state) {
                    final path = state.uri.queryParameters['path'] ?? '';
                    return GithubFileEditorScreen(
                      owner: state.pathParameters['owner']!,
                      repo: state.pathParameters['repo']!,
                      path: path,
                    );
                  },
                ),
                GoRoute(
                  path: 'settings',
                  builder: (context, state) => RepoSettingsScreen(
                    owner: state.pathParameters['owner']!,
                    repo: state.pathParameters['repo']!,
                  ),
                ),
              ],
            ),
          ],
        ),

        // ==== SEARCH BRANCH ====
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),

        // ==== ASSIST BRANCH ====
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/assist',
              builder: (context, state) => const AssistantScreen(),
            ),
          ],
        ),

        // ==== PROFILE BRANCH ====
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),

        // ==== SETTINGS BRANCH ====
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: '/settings/appearance',
              builder: (context, state) => const AppearanceScreen(),
            ),
            GoRoute(
              path: '/settings/ai',
              builder: (context, state) => const AiScreen(),
            ),
            GoRoute(
              path: '/settings/statistics',
              builder: (context, state) => const StatisticsScreen(),
            ),
            GoRoute(
              path: '/settings/about',
              builder: (context, state) => const AboutScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
