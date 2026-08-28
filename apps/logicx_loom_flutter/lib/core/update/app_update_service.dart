import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

class AppUpdateService {
  const AppUpdateService(this.manifestUri);

  final Uri manifestUri;

  Future<AppUpdate?> check() async {
    if (!Platform.isAndroid) return null;
    final response = await http
        .get(manifestUri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final update = AppUpdate.fromJson(
      jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      baseUri: manifestUri,
    );
    final package = await PackageInfo.fromPlatform();
    final installedBuild = int.tryParse(package.buildNumber) ?? 0;
    return update.buildNumber > installedBuild ? update : null;
  }

  Future<void> downloadAndInstall(
    AppUpdate update, {
    required void Function(double progress) onProgress,
  }) async {
    final client = http.Client();
    final request = http.Request('GET', update.apkUri);
    final response = await client.send(request);
    if (response.statusCode != 200) {
      client.close();
      throw const AppUpdateException('The update APK could not be downloaded.');
    }

    final directory = await getTemporaryDirectory();
    final apk = File('${directory.path}/logicx-loom-${update.version}.apk');
    final fileSink = apk.openWrite();
    final digestOutput = AccumulatorSink<Digest>();
    final digestInput = sha256.startChunkedConversion(digestOutput);
    var received = 0;
    try {
      await for (final chunk in response.stream) {
        fileSink.add(chunk);
        digestInput.add(chunk);
        received += chunk.length;
        final total = response.contentLength ?? update.sizeBytes;
        if (total > 0) onProgress(received / total);
      }
    } finally {
      await fileSink.close();
      digestInput.close();
      client.close();
    }

    final actualChecksum = digestOutput.events.single.toString();
    if (actualChecksum != update.sha256.toLowerCase()) {
      await apk.delete();
      throw const AppUpdateException('The update APK checksum is invalid.');
    }
    if (update.sizeBytes > 0 && await apk.length() != update.sizeBytes) {
      await apk.delete();
      throw const AppUpdateException('The update APK size is invalid.');
    }

    final result = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw AppUpdateException(result.message);
    }
  }
}

class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.buildNumber,
    required this.apkUri,
    required this.sha256,
    required this.sizeBytes,
    required this.notes,
    required this.required,
  });

  final String version;
  final int buildNumber;
  final Uri apkUri;
  final String sha256;
  final int sizeBytes;
  final List<String> notes;
  final bool required;

  factory AppUpdate.fromJson(Map<String, dynamic> json, {Uri? baseUri}) =>
      AppUpdate(
        version: json['version'] as String,
        buildNumber: json['buildNumber'] as int,
        apkUri:
            baseUri?.resolve(json['apkUrl'] as String) ??
            Uri.parse(json['apkUrl'] as String),
        sha256: json['sha256'] as String,
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        notes: (json['notes'] as List? ?? []).whereType<String>().toList(),
        required: json['required'] as bool? ?? false,
      );
}

class AppUpdateException implements Exception {
  const AppUpdateException(this.message);

  final String message;
}
