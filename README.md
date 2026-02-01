# AutoGit

A Flutter app for managing local and remote Git repositories, with GitHub authentication.

## GitHub OAuth setup

To use "Continue with GitHub" sign-in you need a **Client ID**. You can optionally set a **Client Secret** for the web flow (browser + local callback).

1. Create a [GitHub OAuth App](https://github.com/settings/developers):
   - **Authorization callback URL**: `http://localhost:8080/callback` (required for web flow if you use a secret).
   - Note the **Client ID**. Generate a **Client Secret** only if you want the web flow (e.g. local dev).

2. **Publishing / open-source builds (no secret):**
   - Enable **Device flow** in your OAuth app settings (GitHub → Settings → Developer settings → OAuth Apps → your app → Enable device flow).
   - Build or run with only the client ID:
   ```bash
   flutter run --dart-define=GITHUB_CLIENT_ID=your_client_id
   # or for release: flutter build apk --dart-define=GITHUB_CLIENT_ID=your_client_id
   ```
   - Users sign in by opening https://github.com/login/device and entering the code shown in the app. No client secret is needed, so you can ship Android/Linux (and other) builds publicly.

3. **Local dev with web flow (optional):**
   - Run with both client ID and secret for the classic browser redirect flow:
   ```bash
   flutter run --dart-define=GITHUB_CLIENT_ID=your_client_id --dart-define=GITHUB_CLIENT_SECRET=your_client_secret
   ```

If `GITHUB_CLIENT_ID` is not set, the GitHub login button shows a configuration message. You can still use **Proceed without Sign In** to use the app without remote repositories.

## Releases and CI

Pushing a **version tag** (e.g. `v1.0.0` or `v1.0.0+2`) on `main` triggers the [Release workflow](.github/workflows/release.yml). It builds:

- **Android**: `.apk` (release APK)
- **Windows**: `.zip` with `autogit.exe` and DLLs (extract and run)
- **Linux**: tarball of the Flutter Linux bundle
- **Arch Linux**: `.pkg.tar.zst` (install with `pacman -U`)
- **Flatpak**: `.flatpak` (install with `flatpak install *.flatpak`)

Flutter’s build version is taken from the tag: `v1.0.0` → build name `1.0.0`, build number `1`; `v1.0.0+2` → build name `1.0.0`, build number `2`.

**Repo setup:** Add a repository variable `GITHUB_CLIENT_ID` (Settings → Secrets and variables → Actions → Variables) so release builds get your OAuth client ID (device flow only; no secret in CI).

## Troubleshooting: Permission denied / Gradle

If you see `PathAccessException: Cannot copy file to ... flutter_assets` or "Gradle does not have execution permission", the project or build dir was likely created as root. Fix ownership and clean:

```bash
# Fix ownership (run once; use your username if needed)
sudo chown -R $(whoami):$(whoami) .

# Clean and run as your normal user (not root)
flutter clean
flutter run -d 192.168.240.112:5555 --dart-define=GITHUB_CLIENT_ID=... --dart-define=GITHUB_CLIENT_SECRET=...
```

Always run `flutter` and `gradle` as your normal user, not root.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
