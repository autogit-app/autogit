# AutoGit Architecture

This document describes the app structure, separation of concerns, and feature boundaries.

## Layers

### Core (`lib/core/`)

Shared infrastructure used across features. **No feature-specific business logic.**

| Area | Purpose |
|------|---------|
| **router/** | GoRouter setup, routes, shell. |
| **providers/** | Theme (theme_persistence, themeModeProvider, colorSchemeSeedProvider). |
| **constants/** | Colors, icons, image paths, strings. |
| **utils/** | Shared helpers (e.g. string_utils, local_git). |
| **widgets/** | Reusable UI (LargeAppBar, ScaffoldWithNavBar, github_repositories list). |

**Note:** GitHub API clients and their Riverpod providers live under **features/github** (see below). Core stays free of GitHub-specific logic.

### Features (`lib/features/`)

Each feature is self-contained with clear boundaries. Preferred structure per feature:

```
feature_name/
  data/          # Models, API clients, repositories (no UI)
  providers/     # Riverpod providers for this feature (optional)
  ui/            # Screens, pages, feature-specific widgets
```

**Dependency rule:** A feature may depend on **core** and on **auth** (for token/user). Features avoid importing other features' `data/` or `ui/` except via explicit, minimal APIs (e.g. auth providers).

---

## Features

### Auth (`features/auth/`)

- **Responsibility:** Sign-in state, GitHub OAuth (device + web flow), anonymous mode.
- **data:** `auth_state.dart`, `github_auth_service.dart`
- **providers:** `auth_provider.dart` (token, username, auth state)
- **ui:** `auth_screen.dart`
- **Consumed by:** Router, all features that need "current user" or token.

### GitHub (`features/github/`)

- **Responsibility:** All GitHub API access and GitHub-specific Riverpod providers.
- **data:** GitHub client (user repos, create/delete repo), contents API, repo API, home API (notifications, starred, etc.), issues/PR API, pages API, templates API, environments API, stats; shared models (e.g. repository_model).
- **providers:** userReposProvider, notificationsProvider, myIssuesProvider, myPullRequestsProvider, githubStatsProvider, etc.
- **ui:** None (screens that use GitHub live under home, repos, profile, search).
- **Consumed by:** home, repos, profile, search, settings (statistics).

### Home (`features/home/`)

- **Responsibility:** Home screen, notifications, starred, watched, issues, PRs, sites, create site, create code repo, projects, discussions, issue/PR detail.
- **data:** None (uses features/github and features/auth).
- **providers:** None (uses features/github providers).
- **ui:** home_screen, notifications_screen, starred_screen, watched_screen, issues_screen, pull_requests_screen, sites_screen, create_site_screen, create_code_repo_screen, projects_screen, discussions_screen, issue_detail_screen, pr_detail_screen, widgets (home_fab, home_card).

### Repos (`features/repos/`)

- **Responsibility:** Browsing and editing repos (GitHub and local).
- **data:** Only if feature-specific (e.g. local repo discovery). GitHub repo/contents access is in features/github.
- **ui:** github_repos_screen, github_repository_screen, github_file_editor_screen, repo_settings_screen, local_repos_screen, local_repository_screen, widgets (github_fab, local_fab).

### Search (`features/search/`)

- **Responsibility:** Search screen, user profile, user repos list.
- **data:** `github_search_service.dart`
- **ui:** search_screen, user_profile_screen, user_repos_screen.

### Profile (`features/profile/`)

- **Responsibility:** Current user profile, pinned repos, contribution link.
- **data:** None (uses features/github, features/auth).
- **ui:** profile_screen.

### Settings (`features/settings/`)

- **Responsibility:** App settings, appearance, AI, statistics, about.
- **data:** None.
- **providers/logic:** ai_settings_providers, settings_providers, statistics_providers (statistics use features/github).
- **ui:** settings_screen, sections (appearance, ai, statistics, about).

### Assist (`features/assist/`)

- **Responsibility:** In-app AI assistant.
- **data:** `chat_service.dart`
- **ui:** assistant_screen.

### Onboarding (`features/onboarding/`)

- **Responsibility:** First-run onboarding flow.
- **ui:** onboarding_screen.

---

## Entry points

- **App:** `lib/main.dart` → `lib/app.dart` (MaterialApp.router, theme from core providers).
- **Router:** `lib/core/router/app_router.dart` (imports feature screens; uses AuthState for redirects).

---

## Naming and imports

### Barrel files (recommended)

Prefer importing from feature/core barrels so dependencies are explicit and refactors are easier:

| Import | Use for |
|--------|--------|
| `package:autogit/core/core.dart` | Theme (themeModeProvider, colorSchemeSeedProvider, AppThemeMode), theme_persistence, isHomeLocalProvider. |
| `package:autogit/features/auth/auth.dart` | Auth state, auth service, auth provider, auth screen. |
| `package:autogit/features/github/github.dart` | All GitHub API and providers (user repos, contents, repo API, templates, environments, home, stats, pages, issues/PRs). |
| `package:autogit/features/repos/repos.dart` | Repo-related data (contents API, repo API, repository model). |

Router, constants, and widgets: keep direct paths, e.g. `package:autogit/core/router/app_router.dart`, `package:autogit/core/widgets/large_app_bar.dart`.

### Conventions

- Use **feature-based imports** where it clarifies ownership.
- **Core** holds only router, theme, constants, utils, shared widgets (no GitHub-specific logic; that lives under the github feature surface).
- New code in home, repos, profile, search, settings can `import 'package:autogit/features/github/github.dart';` instead of multiple core/repos imports.

This layout keeps separation of concerns (core vs features, data vs ui) and makes it clear which feature owns which behavior.
