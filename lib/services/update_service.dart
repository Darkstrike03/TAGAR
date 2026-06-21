import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/update_model.dart';

class UpdateService {
  final String repoOwner;
  final String repoName;

  const UpdateService({
    this.repoOwner = 'Darkstrike03',
    this.repoName = 'TAGAR',
  });

  String get _manifestUrl =>
      'https://raw.githubusercontent.com/$repoOwner/$repoName/main/update_manifest.json';

  Future<UpdateManifest?> fetchManifest() async {
    try {
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(_manifestUrl));
        request.headers['User-Agent'] = 'Tagar/$repoOwner';
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) return null;
        final body = await response.stream.bytesToString();
        return UpdateManifest.fromJson(
          jsonDecode(body) as Map<String, dynamic>,
        );
      } finally {
        client.close();
      }
    } catch (_) {
      return null;
    }
  }

  Future<String?> downloadUpdate({
    required String url,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final fileName = url.split('/').last;
      final file = File('${dir.path}/$fileName');

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) return null;

      final contentLength = response.contentLength ?? 0;
      final bytes = <int>[];
      var received = 0;

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          onProgress(received / contentLength);
        }
      }

      await file.writeAsBytes(bytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  bool verifyChecksum(String filePath, String expectedSha256) {
    try {
      final file = File(filePath);
      final bytes = file.readAsBytesSync();
      final digest = sha256.convert(bytes);
      return digest.toString() == expectedSha256.toLowerCase();
    } catch (_) {
      return false;
    }
  }

  String? platformKey() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    return null;
  }

  Future<bool> installUpdate(String filePath) async {
    try {
      if (Platform.isWindows) {
        await Process.run(filePath, [], runInShell: true);
        return true;
      }
      if (Platform.isAndroid) {
        // Requires open_file or file_provider intent — not yet implemented
        return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
