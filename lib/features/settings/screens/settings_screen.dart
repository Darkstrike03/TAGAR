import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/update_model.dart';
import '../../../services/update_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _updateService = const UpdateService();
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = info.version);
  }

  Future<void> _checkForUpdates() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          margin: EdgeInsets.all(32),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Checking for updates...'),
              ],
            ),
          ),
        ),
      ),
    );

    final manifest = await _updateService.fetchManifest();

    if (!mounted) return;
    Navigator.of(context).pop();

    if (manifest == null) {
      _showErrorDialog();
      return;
    }

    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;

    final currentVersionCode = int.tryParse(info.buildNumber) ?? 0;

    if (manifest.versionCode > currentVersionCode) {
      _showUpdateAvailableDialog(manifest);
    } else {
      _showUpToDateDialog();
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Update Check Failed'),
        content: const Text(
          'Could not check for updates. Make sure you have an internet connection.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUpToDateDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Up to Date'),
        content: Text('You\'re running the latest version ($_appVersion).'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUpdateAvailableDialog(UpdateManifest manifest) {
    final platformKey = _updateService.platformKey();
    final downloadUrl =
        platformKey != null ? manifest.downloadUrl[platformKey] : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.system_update,
                color: AppColors.leafGreen),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Update v${manifest.latestVersion}'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'A new version is available!',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Current: $_appVersion',
                style: AppTextStyles.caption,
              ),
              Text(
                'Latest: ${manifest.latestVersion}',
                style: AppTextStyles.caption,
              ),
              if (manifest.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'What\'s new:',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  manifest.releaseNotes,
                  style: AppTextStyles.caption,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Later'),
          ),
          if (downloadUrl != null)
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _showDownloadDialog(manifest);
              },
              icon: const Icon(Icons.download),
              label: const Text('Download'),
            ),
        ],
      ),
    );
  }

  void _showDownloadDialog(UpdateManifest manifest) {
    final platformKey = _updateService.platformKey();
    final url = platformKey != null ? manifest.downloadUrl[platformKey] : null;
    if (url == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Downloading Update'),
        content: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Downloading...'),
          ],
        ),
      ),
    );

    _updateService.downloadUpdate(url: url).then((filePath) {
      if (!mounted) return;
      Navigator.of(context).pop();

      if (filePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed')),
        );
        return;
      }

      final expectedChecksum = platformKey != null
          ? manifest.sha256Checksum[platformKey]
          : null;
      if (expectedChecksum != null &&
          expectedChecksum.isNotEmpty &&
          !_updateService.verifyChecksum(filePath, expectedChecksum)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checksum mismatch. Download corrupted.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloaded: $filePath'),
          action: SnackBarAction(
            label: 'Install',
            onPressed: () => _updateService.installUpdate(filePath),
          ),
        ),
      );
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Account'),
          _menuItem(Icons.lock_outlined, 'Privacy'),
          _menuItem(Icons.notifications_outlined, 'Notifications'),
          const SizedBox(height: 4),
          _menuItem(Icons.logout, 'Log Out', onTap: _logout),
          const SizedBox(height: 16),
          _section('App'),
          _menuItem(Icons.language_outlined, 'Language'),
          _menuItem(
            Icons.system_update_outlined,
            'Check for Updates',
            onTap: _checkForUpdates,
          ),
          const SizedBox(height: 16),
          _section('About'),
          _infoItem('Version', _appVersion),
          _infoItem('Made with', 'Tagar flower bloom'),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title.toUpperCase(), style: AppTextStyles.caption),
    );
  }

  Widget _menuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.earthBrown),
      title: Text(label, style: AppTextStyles.body),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.sandyBrown,
      ),
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
    );
  }

  Widget _infoItem(String label, String value) {
    return ListTile(
      title: Text(label, style: AppTextStyles.label),
      trailing: Text(value, style: AppTextStyles.caption),
      contentPadding: EdgeInsets.zero,
    );
  }
}
