/// GitHub feature: single entry point for all GitHub API and providers.
///
/// Use: `import 'package:autogit/features/github/github.dart';`
/// to access user repos, contents API, repo API, templates, environments,
/// home (notifications, starred, watched, issues, PRs), stats, and pages API.
library;

export 'package:autogit/core/providers/github.dart';
export 'package:autogit/core/providers/github_environments_api.dart';
export 'package:autogit/core/providers/github_home_api.dart';
export 'package:autogit/core/providers/github_home_providers.dart';
export 'package:autogit/core/providers/github_pages_api.dart';
export 'package:autogit/core/providers/github_stats_providers.dart';
export 'package:autogit/core/providers/github_templates_api.dart';
export 'package:autogit/core/providers/github_user_issue_pr_api.dart';
export 'package:autogit/features/repos/data/github_contents_api.dart';
export 'package:autogit/features/repos/data/github_repo_api.dart';
export 'package:autogit/features/repos/data/repository_model.dart';
