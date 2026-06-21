class UpdateManifest {
  final String latestVersion;
  final int versionCode;
  final int minVersionCode;
  final Map<String, String> downloadUrl;
  final Map<String, String> sha256Checksum;
  final String releaseNotes;

  const UpdateManifest({
    required this.latestVersion,
    required this.versionCode,
    required this.minVersionCode,
    required this.downloadUrl,
    required this.sha256Checksum,
    required this.releaseNotes,
  });

  factory UpdateManifest.fromJson(Map<String, dynamic> json) {
    return UpdateManifest(
      latestVersion: json['latestVersion'] as String,
      versionCode: json['versionCode'] as int,
      minVersionCode: json['minVersionCode'] as int,
      downloadUrl: Map<String, String>.from(json['downloadUrl'] as Map),
      sha256Checksum:
          Map<String, String>.from(json['sha256Checksum'] as Map),
      releaseNotes: json['releaseNotes'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'latestVersion': latestVersion,
        'versionCode': versionCode,
        'minVersionCode': minVersionCode,
        'downloadUrl': downloadUrl,
        'sha256Checksum': sha256Checksum,
        'releaseNotes': releaseNotes,
      };
}
