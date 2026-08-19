import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/models/enums.dart';
import 'package:rakikara/models/master_models.dart';

/// 正常系のJSON一式。個々のテストで一部だけ差し替えて異常系を作る。
Map<String, String> validSources({
  String? colorMaster,
  String? typeAttributes,
  String? pcXKokkaku,
  String? compatibility,
  String? questions,
}) {
  return {
    MasterRepository.colorMasterPath: colorMaster ??
        '''
{"version":1,"colors":[
  {"id":"coral_pink","name":"コーラルピンク","hex":"#FF8B7B","pc_types":["spring"]},
  {"id":"royal_blue","name":"ロイヤルブルー","hex":"#1F4E9C","pc_types":["winter"]}
]}''',
    MasterRepository.typeAttributesPath: typeAttributes ??
        '''
{"version":1,
 "personal_colors":[
  {"id":"spring","color_ids":["coral_pink"],"materials":[],"keywords":[],"description":"春"},
  {"id":"summer","color_ids":[],"materials":[],"keywords":[],"description":"夏"},
  {"id":"autumn","color_ids":[],"materials":[],"keywords":[],"description":"秋"},
  {"id":"winter","color_ids":["royal_blue"],"materials":[],"keywords":[],"description":"冬"}],
 "kokkaku":[
  {"id":"straight","color_ids":[],"materials":[],"keywords":[],"description":"ス"},
  {"id":"wave","color_ids":[],"materials":[],"keywords":[],"description":"ウ"},
  {"id":"natural","color_ids":[],"materials":[],"keywords":[],"description":"ナ"}]}''',
    MasterRepository.pcXKokkakuPath: pcXKokkaku ??
        '{"version":1,"entries":[{"pc_type":"spring","kokkaku_type":"wave","style_text":"春ウェーブ"}]}',
    MasterRepository.compatibilityPath: compatibility ??
        '{"version":1,"entries":[{"zodiac_a":"aries","zodiac_b":"taurus","text":"相性テキスト"}]}',
    MasterRepository.questionsPath: questions ??
        '''
{"version":1,
 "personal_color":[{"id":"pc_q01","text":"Q","choices":[
   {"id":"a","text":"A","scores":{"spring":1}},
   {"id":"b","text":"B","scores":{"winter":1}}]}],
 "kokkaku":[{"id":"kk_q01","text":"Q","choices":[
   {"id":"a","text":"A","scores":{"straight":1}},
   {"id":"b","text":"B"}]}]}''',
  };
}

void main() {
  const repository = MasterRepository();

  group('正常系', () {
    test('マスタ一式を読み込める', () {
      final masters = repository.parse(validSources());

      expect(masters.colors, hasLength(2));
      expect(masters.personalColorAttributes, hasLength(4));
      expect(masters.kokkakuAttributes, hasLength(3));
      expect(masters.personalColorQuestions, hasLength(1));
      expect(masters.kokkakuQuestions, hasLength(1));
    });

    test('色IDから色を引ける', () {
      final masters = repository.parse(validSources());

      expect(masters.colorById('coral_pink')?.name, 'コーラルピンク');
      expect(masters.colorById('coral_pink')?.argb, 0xFFFF8B7B);
      expect(masters.colorById('unknown'), isNull);
    });

    test('PCタイプに似合う色を引ける', () {
      final masters = repository.parse(validSources());

      expect(
        masters.colorsForPersonalColor(PersonalColorType.spring).map((c) => c.id),
        ['coral_pink'],
      );
      expect(masters.colorsForPersonalColor(PersonalColorType.summer), isEmpty);
    });

    test('PC×骨格のテキストを引ける。未登録の組は null', () {
      final masters = repository.parse(validSources());

      expect(
        masters.styleTextFor(PersonalColorType.spring, KokkakuType.wave),
        '春ウェーブ',
      );
      expect(
        masters.styleTextFor(PersonalColorType.autumn, KokkakuType.straight),
        isNull,
      );
    });

    test('星座相性は組の順序を問わずに引ける', () {
      final masters = repository.parse(validSources());

      expect(masters.compatibilityTextFor(Zodiac.aries, Zodiac.taurus), '相性テキスト');
      expect(masters.compatibilityTextFor(Zodiac.taurus, Zodiac.aries), '相性テキスト');
      expect(masters.compatibilityTextFor(Zodiac.leo, Zodiac.virgo), isNull);
    });

    test('scores を省略した選択肢は0点扱いになる', () {
      final masters = repository.parse(validSources());

      expect(masters.kokkakuQuestions.single.choices[1].scores, isEmpty);
    });
  });

  group('異常系はどのファイルの問題か分かる例外になる', () {
    void expectRejected(Map<String, String> sources, String expectedFile, Matcher messageMatcher) {
      expect(
        () => repository.parse(sources),
        throwsA(
          isA<MasterFormatException>()
              .having((e) => e.file, 'file', expectedFile)
              .having((e) => e.message, 'message', messageMatcher),
        ),
      );
    }

    test('JSONとして壊れている', () {
      expectRejected(
        validSources(colorMaster: '{壊れたJSON'),
        MasterRepository.colorMasterPath,
        contains('JSONとして読めません'),
      );
    });

    test('未知のPCタイプIDが混ざっている', () {
      expectRejected(
        validSources(
          colorMaster:
              '{"version":1,"colors":[{"id":"x","name":"X","hex":"#FFFFFF","pc_types":["spring2"]}]}',
        ),
        MasterRepository.colorMasterPath,
        contains('未知の値'),
      );
    });

    test('hex の形式が違う', () {
      expectRejected(
        validSources(
          colorMaster: '{"version":1,"colors":[{"id":"x","name":"X","hex":"FFFFFF","pc_types":[]}]}',
        ),
        MasterRepository.colorMasterPath,
        contains('#RRGGBB'),
      );
    });

    test('色IDが重複している', () {
      expectRejected(
        validSources(
          colorMaster: '''
{"version":1,"colors":[
 {"id":"dup","name":"A","hex":"#FFFFFF","pc_types":[]},
 {"id":"dup","name":"B","hex":"#000000","pc_types":[]}]}''',
        ),
        MasterRepository.colorMasterPath,
        contains('重複'),
      );
    });

    test('type_attributes が存在しない色IDを参照している', () {
      expectRejected(
        validSources(
          typeAttributes: '''
{"version":1,
 "personal_colors":[
  {"id":"spring","color_ids":["nope"],"materials":[],"keywords":[],"description":"春"},
  {"id":"summer","color_ids":[],"materials":[],"keywords":[],"description":"夏"},
  {"id":"autumn","color_ids":[],"materials":[],"keywords":[],"description":"秋"},
  {"id":"winter","color_ids":[],"materials":[],"keywords":[],"description":"冬"}],
 "kokkaku":[
  {"id":"straight","color_ids":[],"materials":[],"keywords":[],"description":"ス"},
  {"id":"wave","color_ids":[],"materials":[],"keywords":[],"description":"ウ"},
  {"id":"natural","color_ids":[],"materials":[],"keywords":[],"description":"ナ"}]}''',
        ),
        MasterRepository.typeAttributesPath,
        contains('color_master.json にありません'),
      );
    });

    test('PCタイプが4件そろっていない', () {
      expectRejected(
        validSources(
          typeAttributes: '''
{"version":1,
 "personal_colors":[
  {"id":"spring","color_ids":[],"materials":[],"keywords":[],"description":"春"}],
 "kokkaku":[
  {"id":"straight","color_ids":[],"materials":[],"keywords":[],"description":"ス"},
  {"id":"wave","color_ids":[],"materials":[],"keywords":[],"description":"ウ"},
  {"id":"natural","color_ids":[],"materials":[],"keywords":[],"description":"ナ"}]}''',
        ),
        MasterRepository.typeAttributesPath,
        contains('4件必要'),
      );
    });

    test('PC×骨格の組み合わせが重複している', () {
      expectRejected(
        validSources(
          pcXKokkaku: '''
{"version":1,"entries":[
 {"pc_type":"spring","kokkaku_type":"wave","style_text":"A"},
 {"pc_type":"spring","kokkaku_type":"wave","style_text":"B"}]}''',
        ),
        MasterRepository.pcXKokkakuPath,
        contains('重複'),
      );
    });

    test('星座の組が順序違いで重複している', () {
      expectRejected(
        validSources(
          compatibility: '''
{"version":1,"entries":[
 {"zodiac_a":"aries","zodiac_b":"taurus","text":"A"},
 {"zodiac_a":"taurus","zodiac_b":"aries","text":"B"}]}''',
        ),
        MasterRepository.compatibilityPath,
        contains('重複'),
      );
    });

    test('選択肢が1つしかない設問', () {
      expectRejected(
        validSources(
          questions: '''
{"version":1,
 "personal_color":[{"id":"pc_q01","text":"Q","choices":[{"id":"a","text":"A","scores":{}}]}],
 "kokkaku":[]}''',
        ),
        MasterRepository.questionsPath,
        contains('2つ以上'),
      );
    });

    test('骨格の設問に骨格以外のタイプidが混ざっている', () {
      expectRejected(
        validSources(
          questions: '''
{"version":1,
 "personal_color":[],
 "kokkaku":[{"id":"kk_q01","text":"Q","choices":[
   {"id":"a","text":"A","scores":{"spring":1}},
   {"id":"b","text":"B","scores":{"wave":1}}]}]}''',
        ),
        MasterRepository.questionsPath,
        contains('未知のタイプid'),
      );
    });
  });
}
