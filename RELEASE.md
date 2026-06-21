# Tagar Release Guide

## Overview

Pushing a Git tag (e.g. `v1.0.1`) triggers a **GitHub Actions** workflow that:

1. Builds `app-release.apk` (Android) on an Ubuntu runner
2. Builds `tagar-setup-*.exe` (Windows installer) on a Windows runner via Inno Setup
3. Computes SHA256 checksums for both
4. Updates `update_manifest.json` with the new version, URLs, and checksums
5. Commits the updated manifest back to the repo
6. Creates a **GitHub Release** with both files attached and auto-generated release notes

You do **not** need Flutter installed locally to build — everything runs in the cloud.

---

## 1. Prerequisites (one-time setup)

### 1a. Enable GitHub Actions on your repo

The workflow file is at `.github/workflows/release.yml`. It's already in the code. Just push it. GitHub Actions should be enabled by default on public repos.

### 1b. First-time authentication

Run this once locally if you haven't already:

```bash
gh auth login
```

Follow the browser login. This lets you push tags from your terminal.

---

## 2. How to release a new version

### Step 1 — Bump the version in `pubspec.yaml`

Open `pubspec.yaml` and update the `version` line:

```yaml
version: 1.0.0+1      # current
version: 1.0.1+2      # new: version name is "1.0.1", build number is "2"
```

Rules:
- **Version name** (`1.0.1`): follows [semver](https://semver.org/) — `MAJOR.MINOR.PATCH`
- **Build number** (`2`): increments by 1 each release
  - `1.0.0+1` → first release
  - `1.0.1+2` → second release
  - `1.1.0+3` → third release

### Step 2 — Commit and push the version bump

```bash
git add pubspec.yaml
git commit -m "Bump to v1.0.1"
git push
```

### Step 3 — Tag and push

```bash
git tag v1.0.1
git push origin v1.0.1
```

**That's it.** The tag name **must** start with `v` (lowercase) to trigger the workflow.

---

## 3. What happens in the cloud

Once you push the tag, go to your repo on GitHub → **Actions** tab → you'll see a workflow run named after the tag.

### Job 1: `build-android` (~3 min)
| Step | Detail |
|------|--------|
| Setup | Java 17 + Flutter |
| Build | `flutter build apk` → universal APK |
| Checksum | `sha256sum` → `android-checksum.txt` |
| Upload | APK + checksum saved as artifact |

### Job 2: `build-windows` (~5 min)
| Step | Detail |
|------|--------|
| Setup | Flutter on Windows |
| Build | `flutter build windows` |
| Package | Builds a single-file installer via Inno Setup → `tagar-setup-*.exe` |
| Checksum | `Get-FileHash` → `windows-checksum.txt` |
| Upload | ZIP + checksum saved as artifact |

### Job 3: `release` (~30 sec)
| Step | Detail |
|------|--------|
| Extract | Reads version name & build number from `pubspec.yaml` |
| Manifest | Rewrites `update_manifest.json` with correct URLs and SHA256 hashes |
| Commit | Pushes updated `update_manifest.json` back to `main` |
| Release | Creates a GitHub Release with both files attached + auto release notes |

---

## 4. After the release

### 4a. Verify on GitHub

1. Go to your repo → **Releases** → you should see the new release
2. Click the release — both `app-release.apk` and `tagar-setup-*.exe` should be attached
3. Go to the repo root — `update_manifest.json` should show the updated version

### 4b. Test the in-app update flow

1. Run the app on your phone/PC
2. Go to **Settings → Check for Updates**
3. If the current version is older than the release, it should show "Update Available"
4. Tap **Download** — it will download, verify SHA256, and prompt to install

### 4c. Share with friends

Send them the GitHub release link:
```
https://github.com/Darkstrike03/TAGAR/releases/tag/v1.0.1
```

**Android:** Friends download `app-release.apk`, enable "Install from unknown apps", and install.

**Windows:** Friends download `tagar-setup-*.exe`, double-click, and follow the installer. It installs to Start Menu and optionally creates a desktop shortcut.

---

## 5. Common issues & fixes

### Workflow didn't run

Check:
- Tag name starts with `v` (e.g. `v1.0.1`, not `1.0.1` or `V1.0.1`)
- Tag was pushed: `git push origin v1.0.1`
- GitHub Actions is enabled on the repo: **Settings → Actions → General → Allow all actions**

### Build failed on `flutter build windows`

Windows builds need the Visual Studio Build Tools. The `windows-latest` runner has them pre-installed. If it fails, the issue is usually:
- A missing plugin that doesn't support Windows → check `flutter doctor -v` on Windows
- Try building locally first: `flutter build windows` and fix any errors

### Build failed on `flutter build apk`

Check:
- Java 17 is available (the workflow sets it up)
- All dependencies are compatible with Android
- Try building locally: `flutter build apk` and fix any errors

### Manifest update commit triggered another workflow run

The commit message includes `[skip ci]`, which tells GitHub not to trigger Actions for that commit. If it still triggers, check your repo's Actions settings — some configurations ignore `[skip ci]`.

### Checksum mismatch in the app

If the SHA256 in the manifest doesn't match the downloaded file:
1. The download was corrupted → retry
2. The manifest wasn't updated properly → check the release's `update_manifest.json` on the `main` branch
3. Re-run the workflow by deleting the tag and pushing again:
   ```bash
   git tag -d v1.0.1
   git push origin :refs/tags/v1.0.1
   # fix the issue, then re-tag
   git tag v1.0.1
   git push origin v1.0.1
   ```

### "App not installed" on Android

The APK is built with **debug signing** by default. On Android:
- Go to **Settings → Security → Install unknown apps** → enable for your file manager
- You may see a "Blocked by Play Protect" warning — tap **Install anyway** (it's your own app)

For wider distribution without warnings, you'd need to [sign with a release keystore](https://flutter.dev/docs/deployment/android#signing-the-app).

---

## 6. One-time setup checklist

- [ ] Push the repo to GitHub (already done)
- [ ] GitHub Actions is enabled on the repo (default for public repos)
- [ ] `gh auth login` done locally
- [ ] First release: `git tag v1.0.0 && git push origin v1.0.0`

---

## 7. Quick reference

```bash
# Full release flow (3 commands)
git add pubspec.yaml && git commit -m "Bump to v1.0.1"
git push
git tag v1.0.1 && git push origin v1.0.1

# Delete a bad tag (local + remote)
git tag -d v1.0.1
git push origin :refs/tags/v1.0.1
```
