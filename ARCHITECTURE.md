# Tagar — Architecture & Folder Structure

> **Goal:** A WeChat-like super app. Phase 1 = WhatsApp-like chat app.
> **State Management:** Riverpod
> **Backend:** Supabase
> **Navigation:** GoRouter (with bottom nav shell)

---

## 1. Folder Structure

```
lib/
├── core/                          # Shared foundations
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── api_constants.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   └── app_text_styles.dart
│   ├── utils/
│   │   ├── validators.dart
│   │   ├── formatters.dart
│   │   └── extensions.dart
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── loading_indicator.dart
│       ├── error_display.dart
│       └── avatar_widget.dart
│
├── services/                      # Backend & infra layer
│   ├── supabase_client.dart       # Supabase init singleton
│   ├── auth_service.dart          # Phone OTP sign-in
│   ├── chat_service.dart          # Real-time messaging via Supabase Realtime
│   ├── language_pack_service.dart # Fetch & install packs from GitHub repos
│   └── update_service.dart        # GitHub-hosted update checking + download + checksum
│
├── models/                        # Shared data models
│   ├── user_model.dart
│   ├── message_model.dart
│   ├── conversation_model.dart
│   ├── language_pack_model.dart
│   └── update_model.dart          # Update manifest model
│
├── providers/                     # Global Riverpod providers
│   ├── auth_provider.dart
│   └── theme_provider.dart
│
├── router/
│   ├── app_router.dart            # GoRouter with ShellRoute for bottom nav
│   └── route_names.dart           # Named route constants
│
├── features/                      # Feature modules (one folder per feature)
│   ├── splash/
│   │   └── screens/
│   │       └── splash_screen.dart
│   │
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── phone_input_screen.dart
│   │   │   └── otp_verification_screen.dart
│   │   └── providers/
│   │       └── auth_provider.dart
│   │
│   ├── chat/                      # Tab 1
│   │   ├── screens/
│   │   │   ├── chat_list_screen.dart
│   │   │   └── chat_screen.dart
│   │   ├── widgets/
│   │   │   ├── chat_tile.dart
│   │   │   └── message_bubble.dart
│   │   └── providers/
│   │       ├── chat_list_provider.dart
│   │       └── chat_provider.dart
│   │
│   ├── updates/                   # Tab 2 — Status/Stories
│   │   ├── screens/
│   │   │   └── updates_screen.dart
│   │   ├── widgets/
│   │   │   └── status_tile.dart
│   │   └── providers/
│   │       └── updates_provider.dart
│   │
│   ├── language_store/            # Tab 3 — Language pack marketplace
│   │   ├── screens/
│   │   │   └── language_store_screen.dart
│   │   ├── widgets/
│   │   │   └── language_pack_card.dart
│   │   └── providers/
│   │       └── language_store_provider.dart
│   │
│   ├── profile/                   # Tab 4
│   │   ├── screens/
│   │   │   └── profile_screen.dart
│   │   ├── widgets/
│   │   │   └── profile_header.dart
│   │   └── providers/
│   │       └── profile_provider.dart
│   │
│   └── settings/                  # Nested from profile
│       ├── screens/
│       │   └── settings_screen.dart
│       └── providers/
│           └── settings_provider.dart
│
├── mini_apps/                     # Phase 2+ — Super app expansion
│   ├── framework/
│   │   ├── mini_app_base.dart     # Abstract base class for all mini-apps
│   │   ├── mini_app_registry.dart # Global registry of installed mini-apps
│   │   └── mini_app_host.dart     # Container widget that hosts a mini-app
│   └── apps/                      # Individual mini-apps (one folder each)
│       └── (placeholder)
│
├── app.dart                       # MaterialApp.router() — app root
└── main.dart                      # Entry point (ProviderScope + runApp)
```

---

## 2. Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Files | `snake_case.dart` | `chat_list_screen.dart` |
| Classes | `PascalCase` | `ChatListScreen` |
| Variables/Fields | `camelCase` | `chatList` |
| Private members | `_camelCase` | `_chatList` |
| Providers | `camelCase` + `Provider` | `chatListProvider` |
| Services | `camelCase` + `Service` | `chatService` |
| Models | `PascalCase` + `Model` | `MessageModel` |
| Route names | `snake_case` string | `'chat_screen'` |
| Feature folders | `snake_case` | `language_store/` |
| Sub-folders | Always plural | `screens/`, `widgets/`, `providers/` |

---

## 3. Feature Anatomy (Rule)

Every feature folder **must** follow this exact structure:

```
feature_name/
├── screens/         # Page-level widgets (one file per route)
├── widgets/         # Feature-specific reusable widgets
└── providers/       # Riverpod providers for this feature
```

- **No feature** should import from another feature's internals. If code is shared between features, move it to `core/`, `services/`, or `models/`.
- **Screens** are the only files referenced by the router.
- **Providers** handle state. Screens read providers, never manage state themselves.

---

## 4. Dependency Rules

```
features/  ---imports--->  core/, services/, models/, providers/
            (NEVER imports another feature/)
```

```
core/      ---imports--->  (nothing project-internal)
services/  ---imports--->  core/, models/
models/    ---imports--->  (nothing project-internal)
providers/ ---imports--->  services/, models/
```

**Golden rule:** A feature folder is a sealed module. If two features need the same thing, extract it upward into `core/`, `services/`, or `models/`.

---

## 5. Packages (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  supabase_flutter: ^2.5.0
  go_router: ^14.0.0
  json_annotation: ^4.9.0
  cached_network_image: ^3.3.0
  intl: ^0.19.0
  shared_preferences: ^2.2.0
  http: ^1.2.0
  crypto: ^3.0.0
  path_provider: ^2.1.0
  open_file: ^3.3.0        # Android APK installer trigger
  process_run: ^1.0.0      # Windows EXE launcher (with sudo prompt)

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  flutter_lints: ^6.0.0
```

---

## 6. Build Order (Phase 1)

| Step | What | Why |
|------|------|------|
| **1** | `core/` + `app.dart` | Theme, shared widgets, shell scaffold with bottom nav |
| **2** | `supabase_client.dart` + `auth/` | Login flow — everything else requires auth |
| **3** | `chat/` + `chat_service.dart` | Core messaging — the heart of Phase 1 |
| **4** | `updates/` | Status/stories feature |
| **5** | `language_store/` | Browse & download language packs (store UI only) |
| **6** | `profile/` + `settings/` | User profile + app settings |
| **7** | `mini_apps/framework/` | Laying groundwork for Phase 2 |

---

## 7. Phase 1.5 — Live Translation

When ready to add live translation:

1. The `language_pack_service.dart` already handles downloading and indexing pack files from GitHub.
2. In the chat screen, add a "Translate" toggle per message or per conversation.
3. Each `MessageBubble` can optionally render translated text using the active language pack.
4. The `language_store/` screen becomes the discovery UI for new packs.

---

## 8. Mini-App Framework (Phase 2+)

The `mini_apps/framework/` directory provides a lightweight plugin system:

- **`MiniAppBase`** — Abstract class every mini-app extends. Defines lifecycle (`onInit`, `onDestroy`), metadata (`name`, `icon`, `version`), and a `build()` method returning the app's widget tree.
- **`MiniAppRegistry`** — Singleton map of `String` → `MiniAppBase`. Apps register themselves at startup. The main app queries this to display the mini-app drawer/launcher.
- **`MiniAppHost`** — A wrapper widget that receives a registered mini-app ID and renders its UI safely within a sandboxed container (scoped theme, isolated navigation stack).

When adding a new mini-app:
1. Create a folder under `mini_apps/apps/<app_name>/`.
2. Create a class extending `MiniAppBase`.
3. Register it in `MiniAppRegistry.register()` during app initialization.
4. The launcher UI (e.g. a grid in a tab) reads the registry and renders each app's icon.

---

## 9. Update System (Phase 1)

> **Mechanism:** GitHub Releases as the update server. No Play Store / MS Store dependency.

### 9a. How releases work

1. You tag and push a new release on GitHub (e.g. `v1.0.1`).
2. Attach `tagar-v1.0.1.apk` and `tagar-setup-v1.0.1.exe` as release assets.
3. Maintain a `update_manifest.json` as a committed file in the repo (served via `raw.githubusercontent.com` or GitHub Pages):

   ```json
   {
     "latestVersion": "1.0.1",
     "versionCode": 2,
     "minVersionCode": 1,
     "downloadUrl": {
       "android": "https://github.com/<owner>/tagar/releases/download/v1.0.1/tagar-v1.0.1.apk",
       "windows": "https://github.com/<owner>/tagar/releases/download/v1.0.1/tagar-setup-v1.0.1.exe"
     },
     "sha256Checksum": {
       "android": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
       "windows": "d7a8fbb307d7809469ca9abcb0082e4f8a565d4f5c8f8a8f8a8f8a8f8a8f8a8f"
     },
     "releaseNotes": "Added live translation, fixed crash on empty chats"
   }
   ```

### 9b. Client-side flow (`update_service.dart`)

| Step | Action |
|------|--------|
| **1** | Fetch `update_manifest.json` from GitHub |
| **2** | Compare `versionCode` against `package_info`'s current version |
| **3** | If newer → show notification / badge in Settings |
| **4** | User taps "Update" → start download with progress callback |
| **5** | Compute SHA256 of downloaded file |
| **6** | Compare against manifest's `sha256Checksum`; fail if mismatch |
| **7a** | **Android:** Open APK via `FileProvider` + `Intent.ACTION_VIEW` |
| **7b** | **Windows:** Launch EXE via `Process.run` (triggers UAC prompt for installer) |
| **8** | On success → delete downloaded file from cache |

### 9c. Checksum integrity (non-negotiable)

- SHA256 hash is computed using `dart:io`'s `File` + `crypto` package's `sha256.convert()`.
- If checksum does not match the manifest, the downloaded file is **deleted immediately** and the user sees an error alert — no silent fallback.
- The manifest itself is served over HTTPS; TLS guarantees manifest integrity.

### 9d. UI entry points

- **Settings screen:** "Check for Updates" button + last checked timestamp.
- **Splash screen (silent):** Background check on launch; if update found, show a non-blocking banner.
- **Optional:** A "What's New" dialog after update installation (reads `releaseNotes` from manifest).

### 9e. Files to add

```
lib/
├── models/
│   └── update_model.dart          # UpdateManifest model + JSON parsing
└── services/
    └── update_service.dart        # checkForUpdate(), downloadUpdate(), verifyChecksum()
```
