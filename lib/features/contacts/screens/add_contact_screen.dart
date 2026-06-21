import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../providers/contacts_provider.dart';

enum AddContactMode { qr, manual }

class AddContactScreen extends ConsumerStatefulWidget {
  const AddContactScreen({super.key, this.initialMode = AddContactMode.qr});

  final AddContactMode initialMode;

  @override
  ConsumerState<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends ConsumerState<AddContactScreen> {
  late AddContactMode _mode;
  final _tagarIdController = TextEditingController();
  String? _scannedTagarId;
  Map<String, dynamic>? _foundUser;
  String? _error;
  bool _searching = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _tagarIdController.dispose();
    super.dispose();
  }

  Future<void> _lookupUser(String tagarId) async {
    setState(() {
      _searching = true;
      _error = null;
      _foundUser = null;
    });
    final svc = ref.read(contactServiceProvider);
    final user = await svc.findUserByTagarId(tagarId.trim());
    setState(() {
      _searching = false;
      _foundUser = user;
      if (user == null) {
        _error = 'No user found with that tagar_id';
      }
    });
  }

  Future<void> _sendRequest() async {
    if (_foundUser == null) return;
    setState(() => _sending = true);
    try {
      final svc = ref.read(contactServiceProvider);
      final toId = _foundUser!['id'] as String;
      final toTagarId = _foundUser!['tagar_id'] as String;
      await svc.sendRequest(toId, toTagarId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend request sent!')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'Failed to send request');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.petalWhite,
      appBar: AppBar(
        title: Text(_mode == AddContactMode.qr ? 'Scan QR' : 'Add by Tagar ID'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _mode = _mode == AddContactMode.qr
                    ? AddContactMode.manual
                    : AddContactMode.qr;
                _scannedTagarId = null;
                _foundUser = null;
                _error = null;
              });
            },
            child: Text(
              _mode == AddContactMode.qr ? 'Manual' : 'Scan QR',
              style: AppTextStyles.label.copyWith(color: AppColors.riverBlue),
            ),
          ),
        ],
      ),
      body: _mode == AddContactMode.qr ? _buildQrView() : _buildManualView(),
    );
  }

  Widget _buildQrView() {
    if (_scannedTagarId != null) {
      return _buildUserPreview();
    }

    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.startsWith('tag_#')) {
                  setState(() => _scannedTagarId = raw);
                  _lookupUser(raw);
                  return;
                }
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Point your camera at a Tagar QR code',
            style: AppTextStyles.label,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildManualView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Text('Enter their tagar_id', style: AppTextStyles.h1),
          const SizedBox(height: 8),
          Text(
            'Ask them to share their tagar_id from their profile',
            style: AppTextStyles.label,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _tagarIdController,
            decoration: InputDecoration(
              hintText: 'tag_#A1B2C3',
              prefixIcon: const Icon(Icons.tag_outlined),
              filled: true,
              fillColor: AppColors.barkCream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (v) => _lookupUser(v),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Look up',
            loading: _searching,
            onPressed: () => _lookupUser(_tagarIdController.text),
          ),
          const SizedBox(height: 24),
          if (_foundUser != null) _buildUserPreview(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!, style: const TextStyle(color: AppColors.error)),
            ),
        ],
      ),
    );
  }

  Widget _buildUserPreview() {
    if (_foundUser == null) return const SizedBox.shrink();
    final name = _foundUser!['profile_name'] as String? ?? 'User';
    final tagarId = _foundUser!['tagar_id'] as String;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.barkCream,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          QrImageView(
            data: tagarId,
            version: QrVersions.auto,
            size: 120,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.forestGreen,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.leafGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(name, style: AppTextStyles.h2),
          const SizedBox(height: 4),
          Text(tagarId, style: AppTextStyles.label),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: _scannedTagarId != null
                      ? 'Send Request'
                      : 'Send Friend Request',
                  loading: _sending,
                  onPressed: _sending ? null : _sendRequest,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
