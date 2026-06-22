import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:crop_your_image/crop_your_image.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingBanner = false;
  bool _isUploadingAvatar = false;

  Future<void> _editDisplayName(String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 50,
          decoration: const InputDecoration(
            hintText: 'What should we call you?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final userId = Supabase.instance.client.auth.currentUser!.id;
    await Supabase.instance.client
        .from('user_data')
        .update({'profile_name': name})
        .eq('id', userId);
    ref.invalidate(userDataProvider(userId));
  }

  Future<ImageSource?> _pickSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List?> _cropImage({
    required Uint8List imageBytes,
    required bool circleShape,
  }) {
    final controller = CropController();
    return Navigator.of(context, rootNavigator: true).push<Uint8List>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Crop Image'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(ctx),
            ),
            actions: [
              TextButton(
                onPressed: () => controller.crop(),
                child: const Text('Done',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          body: Crop(
            image: imageBytes,
            controller: controller,
            interactive: true,
            onCropped: (cropped) {
              if (ctx.mounted) {
                Navigator.pop(ctx, cropped);
              }
            },
            withCircleUi: circleShape,
            aspectRatio: circleShape ? 1 : 3,
            initialSize: 0.9,
            baseColor: Colors.black,
            maskColor: Colors.black54,
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(String field) async {
    final source = await _pickSource();
    if (source == null) return;

    setState(() {
      if (field == 'profile_picture') {
        _isUploadingAvatar = true;
      } else {
        _isUploadingBanner = true;
      }
    });

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image == null) return;

      final rawBytes = await image.readAsBytes();

      final isProfile = field == 'profile_picture';
      final croppedBytes = await _cropImage(
        imageBytes: rawBytes,
        circleShape: isProfile,
      );

      if (croppedBytes == null) return;

      final userId = Supabase.instance.client.auth.currentUser!.id;
      final path = '$userId/$field.jpg';

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) throw Exception('Not logged in');

      final storageUrl = Supabase.instance.client.storage.url;
      final uri = Uri.parse('$storageUrl/object/profiles/$path');

      final uploadResponse = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'apiKey': dotenv.env['SUPABASE_ANON_KEY']!,
          'x-upsert': 'true',
          'Content-Type': 'image/jpeg',
        },
        body: croppedBytes,
      );

      if (uploadResponse.statusCode != 200 &&
          uploadResponse.statusCode != 201) {
        throw StorageException(
          'Upload failed: ${uploadResponse.body}',
          statusCode: uploadResponse.statusCode.toString(),
        );
      }

      final version = DateTime.now().millisecondsSinceEpoch;
      final publicUrl =
          '$storageUrl/object/public/profiles/$path?v=$version';

      await Supabase.instance.client
          .from('user_data')
          .update({field: publicUrl})
          .eq('id', userId);

      ref.invalidate(userDataProvider(userId));
    } on StorageException catch (e) {
      if (mounted) {
        var msg = 'Upload failed';
        if (e.statusCode == '404') {
          msg =
              'Storage bucket "profiles" not found. Create it in Supabase dashboard → Storage.';
        } else if (e.statusCode == '403') {
          msg =
              'Upload denied — add INSERT RLS policy on storage.objects for bucket "profiles".';
        } else if (e.statusCode == '401') {
          msg = 'Session expired. Please log out and log in again.';
        } else {
          msg = 'Upload error (${e.statusCode}): ${e.message}';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
        );
      }
    } catch (e, st) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.runtimeType}: $e'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
      debugPrint('Profile image upload error: $e\n$st');
    } finally {
      setState(() {
        _isUploadingBanner = false;
        _isUploadingAvatar = false;
      });
    }
  }

  void _showAboutTagar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 48),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text('Tagar', style: AppTextStyles.h1),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'A nature-inspired messaging app',
                  style: AppTextStyles.label,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tagar is a messaging app with real-time communication, '
                'QR code contact sharing, and a friend request system. '
                'Built with Flutter and powered by Supabase.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 16),
              Text('Features', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 8),
              _aboutFeature('Real-time messaging via Supabase Realtime'),
              _aboutFeature('Add contacts using QR codes or tagar IDs'),
              _aboutFeature('Friend request system'),
              _aboutFeature('Cross-platform (Android, Windows)'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _aboutFeature(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: AppColors.leafGreen)),
          Expanded(
            child: Text(text, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final userDataAsync = ref.watch(userDataProvider(user.id));
        return userDataAsync.when(
          data: (userData) => _buildContent(user, userData),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }

  Widget _buildContent(User user, UserData? userData) {
    final displayName =
        userData?.profileName ?? user.phone ?? 'User';
    final tagarId = userData?.tagarId ?? '';
    final username = userData?.username;

    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      body: ListView(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => _pickImage('banner_picture'),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.sandyBrown,
                    image: userData?.bannerPicture != null
                        ? DecorationImage(
                            image: CachedNetworkImageProvider(
                                userData!.bannerPicture!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x99000000),
                        ],
                      ),
                    ),
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.all(12),
                    child: _isUploadingBanner
                        ? const CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white)
                        : const Icon(Icons.camera_alt,
                            color: Colors.white70),
                  ),
                ),
              ),
              Positioned(
                bottom: -48,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => _pickImage('profile_picture'),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AvatarWidget(
                        imageUrl: userData?.profilePicture,
                        name: displayName,
                        size: 96,
                      ),
                      if (_isUploadingAvatar)
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 56),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: AppTextStyles.h1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _editDisplayName(displayName),
                  child: const Icon(Icons.edit,
                      size: 18, color: AppColors.sandyBrown),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              tagarId.isNotEmpty ? '@$tagarId' : '',
              style: AppTextStyles.label,
            ),
          ),
          if (username != null && username.isNotEmpty) ...[
            const SizedBox(height: 2),
            Center(
              child: Text(
                username,
                style: AppTextStyles.caption,
              ),
            ),
          ],
          const SizedBox(height: 32),
          const Divider(height: 1, color: AppColors.barkCream),
          _menuItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            onTap: () => context.push('/settings'),
          ),
          const Divider(height: 1, indent: 40, color: AppColors.barkCream),
          _menuItem(
            icon: Icons.info_outline,
            label: 'About Tagar',
            onTap: _showAboutTagar,
          ),
          const Divider(height: 1, color: AppColors.barkCream),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.earthBrown),
      title: Text(label, style: AppTextStyles.body),
      trailing:
          const Icon(Icons.chevron_right, color: AppColors.sandyBrown),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
