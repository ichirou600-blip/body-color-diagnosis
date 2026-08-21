import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/logic/compatibility.dart';
import 'package:rakikara/models/enums.dart';

/// 相性診断は同梱の78件がそのまま結果になるので、仮データではなく実データで見る。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('12×12 のどの組み合わせでも結果が返る', () async {
    final masters = await const MasterRepository().load();

    for (final mine in Zodiac.values) {
      for (final partner in Zodiac.values) {
        // その星座の期間に必ず入る日付を作る
        final birthday = DateTime(2008, partner.fromMonth, partner.fromDay);
        final result = judgeCompatibility(
          masters: masters,
          myZodiac: mine,
          partnerBirthday: birthday,
        );

        expect(result, isNotNull, reason: '${mine.label} × ${partner.label}');
        expect(result!.partnerZodiac, partner);
        expect(result.text, isNotEmpty);
      }
    }
  });

  test('自分と相手を入れ替えても同じテキストになる', () async {
    final masters = await const MasterRepository().load();

    for (final a in Zodiac.values) {
      for (final b in Zodiac.values) {
        final forward = judgeCompatibility(
          masters: masters,
          myZodiac: a,
          partnerBirthday: DateTime(2008, b.fromMonth, b.fromDay),
        );
        final backward = judgeCompatibility(
          masters: masters,
          myZodiac: b,
          partnerBirthday: DateTime(2008, a.fromMonth, a.fromDay),
        );

        expect(forward!.text, backward!.text, reason: '${a.label} × ${b.label}');
      }
    }
  });

  test('同じ星座同士だと分かる', () async {
    final masters = await const MasterRepository().load();

    final same = judgeCompatibility(
      masters: masters,
      myZodiac: Zodiac.leo,
      partnerBirthday: DateTime(2008, 8, 1),
    );
    final different = judgeCompatibility(
      masters: masters,
      myZodiac: Zodiac.leo,
      partnerBirthday: DateTime(2008, 1, 1),
    );

    expect(same!.isSameZodiac, isTrue);
    expect(different!.isSameZodiac, isFalse);
    expect(different.partnerZodiac, Zodiac.capricorn);
  });

  test('相手の誕生日は星座に変換されるだけで、結果に残らない', () async {
    final masters = await const MasterRepository().load();

    final result = judgeCompatibility(
      masters: masters,
      myZodiac: Zodiac.aries,
      partnerBirthday: DateTime(2007, 11, 3),
    );

    // 結果が持つのは星座だけ。誕生日そのものは保持しない。
    expect(result!.partnerZodiac, Zodiac.scorpio);
    expect(result.text, isNotEmpty);
  });

  test('テキストが未登録の組み合わせなら null を返す', () {
    // 相性データを1件だけにした状態を作る
    final masters = const MasterRepository().parse({
      MasterRepository.colorMasterPath:
          '{"version":1,"colors":[{"id":"c","name":"色","hex":"#FFFFFF","pc_types":[]}]}',
      MasterRepository.typeAttributesPath: '''
{"version":1,
 "personal_colors":[
  {"id":"spring","color_ids":[],"materials":[],"keywords":[],"description":"春"},
  {"id":"summer","color_ids":[],"materials":[],"keywords":[],"description":"夏"},
  {"id":"autumn","color_ids":[],"materials":[],"keywords":[],"description":"秋"},
  {"id":"winter","color_ids":[],"materials":[],"keywords":[],"description":"冬"}],
 "kokkaku":[
  {"id":"straight","color_ids":[],"materials":[],"keywords":[],"description":"ス"},
  {"id":"wave","color_ids":[],"materials":[],"keywords":[],"description":"ウ"},
  {"id":"natural","color_ids":[],"materials":[],"keywords":[],"description":"ナ"}]}''',
      MasterRepository.pcXKokkakuPath: '{"version":1,"entries":[]}',
      MasterRepository.compatibilityPath:
          '{"version":1,"entries":[{"zodiac_a":"aries","zodiac_b":"aries","text":"A"}]}',
      MasterRepository.questionsPath:
          '{"version":1,"personal_color":[],"kokkaku":[]}',
    });

    final result = judgeCompatibility(
      masters: masters,
      myZodiac: Zodiac.leo,
      partnerBirthday: DateTime(2008, 5, 1),
    );

    expect(result, isNull);
  });
}
