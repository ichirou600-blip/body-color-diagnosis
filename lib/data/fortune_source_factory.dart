import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'daily_fortune_source.dart';
import 'firestore_daily_fortune_source.dart';

/// 占いの取得元を決める。
///
/// Firebase の設定ファイル（`GoogleService-Info.plist` / `google-services.json`）が
/// まだ置かれていない環境では初期化に失敗する。そこでアプリを落とさず、
/// 端末内の仮データに落とす。診断・シェア・相性は Firebase なしで動くので、
/// 設定が終わるまで開発とTestFlight配布を止めないための逃げ道。
///
/// 設定が済んでいれば Firestore から読む。
Future<DailyFortuneSource> createDailyFortuneSource() async {
  try {
    await Firebase.initializeApp();
    return FirestoreDailyFortuneSource(FirebaseFirestore.instance);
  } catch (error) {
    debugPrint(
      'Firebase を初期化できなかったため、占いは端末内の仮データを使います: $error',
    );
    return const LocalDailyFortuneSource();
  }
}
