import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Firebase の設定ファイルまわりを機械的に見張る。
///
/// ファイルを置いただけでは足りず、
/// **iOS は Xcode プロジェクトへの登録、Android は Gradle プラグインの適用**が要る。
/// どちらも欠けると `Firebase.initializeApp()` が失敗し、
/// 占いが端末内の仮データのまま（毎日同じ内容）で気づきにくい。
/// `docs/STEP6_SETUP.md` 参照。
void main() {
  const packageId = 'com.ichirou600.rakikara';
  const projectId = 'rakikara-37acc';

  test('iOS の設定ファイルがバンドルIDとプロジェクトに一致している', () {
    final plist = File('ios/Runner/GoogleService-Info.plist').readAsStringSync();

    expect(_plistString(plist, 'BUNDLE_ID'), packageId);
    expect(_plistString(plist, 'PROJECT_ID'), projectId);
  });

  test('iOS の設定ファイルが Xcode のリソースに入っている', () {
    // ファイルを置くだけでは .app に同梱されない。
    final pbxproj =
        File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

    expect(
      pbxproj,
      contains('GoogleService-Info.plist in Resources'),
      reason: 'Copy Bundle Resources に入っていないと実機で初期化に失敗する',
    );
  });

  test('Android の設定ファイルがパッケージ名とプロジェクトに一致している', () {
    final json = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final info = json['project_info'] as Map<String, dynamic>;
    expect(info['project_id'], projectId);

    final clients = json['client'] as List<dynamic>;
    final packageNames = clients.map((client) {
      final clientInfo = (client as Map<String, dynamic>)['client_info']
          as Map<String, dynamic>;
      final androidInfo =
          clientInfo['android_client_info'] as Map<String, dynamic>;
      return androidInfo['package_name'];
    });
    expect(packageNames, contains(packageId));
  });

  test('Android で google-services プラグインを適用している', () {
    // これが無いと google-services.json が読まれず、既定の設定が作られない。
    final settings = File('android/settings.gradle.kts').readAsStringSync();
    final appBuild = File('android/app/build.gradle.kts').readAsStringSync();

    expect(settings, contains('com.google.gms.google-services'));
    expect(appBuild, contains('id("com.google.gms.google-services")'));
  });

  test('iOS と Android で同じ Firebase プロジェクトを見ている', () {
    final plist = File('ios/Runner/GoogleService-Info.plist').readAsStringSync();
    final json = jsonDecode(
      File('android/app/google-services.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final info = json['project_info'] as Map<String, dynamic>;

    expect(_plistString(plist, 'PROJECT_ID'), info['project_id']);
    expect(_plistString(plist, 'GCM_SENDER_ID'), info['project_number']);
  });
}

/// `<key>NAME</key><string>VALUE</string>` から VALUE を取り出す。
String? _plistString(String plist, String key) {
  final match = RegExp(
    '<key>$key</key>\\s*<string>([^<]*)</string>',
  ).firstMatch(plist);
  return match?.group(1);
}
