import 'package:flutter_test/flutter_test.dart';
import 'package:logicx_loom_flutter/core/update/app_update_service.dart';

void main() {
  test('reads the portal update manifest', () {
    final update = AppUpdate.fromJson(
      const {
        'version': '1.0.2',
        'buildNumber': 10002,
        'apkUrl': '/storage/mobile/release/logicx-loom.apk',
        'sha256': 'abc123',
        'sizeBytes': 1024,
        'required': false,
        'notes': ['Adds portal updates.'],
      },
      baseUri: Uri.parse(
        'https://log.logicx.in/storage/mobile/release/update.json',
      ),
    );

    expect(update.version, '1.0.2');
    expect(update.buildNumber, 10002);
    expect(update.apkUri.host, 'log.logicx.in');
    expect(update.sizeBytes, 1024);
    expect(update.notes, ['Adds portal updates.']);
    expect(update.required, isFalse);
  });
}
