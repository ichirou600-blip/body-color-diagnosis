import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/master_repository.dart';
import 'package:rakikara/logic/suggestion_engine.dart';
import 'package:rakikara/models/daily_fortune.dart';
import 'package:rakikara/models/enums.dart';
import 'package:rakikara/models/user_profile.dart';

import '../data/master_repository_test.dart' show validSources;

void main() {
  // fixture: イエベ春に似合うのは coral_pink、ブルベ冬に似合うのは royal_blue
  final masters = const MasterRepository().parse(validSources());
  const engine = SuggestionEngine();

  final springProfile = UserProfile(
    personalColor: PersonalColorType.spring,
    kokkaku: KokkakuType.wave,
    birthday: DateTime(2008, 5, 14),
  );

  DailyFortune fortune({
    required String luckyColorId,
    ItemCategory category = ItemCategory.nail,
  }) {
    return DailyFortune(
      date: DateTime(2026, 8, 21),
      zodiac: Zodiac.taurus,
      message: '今日はいい日。',
      luckyColorId: luckyColorId,
      luckyItemCategory: category,
    );
  }

  List<SuggestionCard> run(UserProfile profile, DailyFortune daily) {
    return engine.run(
      SuggestionContext(profile: profile, fortune: daily, masters: masters),
    );
  }

  group('ラッキーカラーが似合う色と一致するとき', () {
    test('その色でコーデ・ネイル・ヘアアクセを提案する', () {
      final cards = run(springProfile, fortune(luckyColorId: 'coral_pink'));

      expect(cards, hasLength(3));
      expect(cards.map((c) => c.title),
          ['今日のコーデ', '今日のネイル', '今日のヘアアクセ']);
      for (final card in cards) {
        expect(card.color?.id, 'coral_pink');
        expect(card.body, contains('得意な色'));
        expect(card.searchUrl, isNotNull);
      }
    });

    test('占いのラッキーアイテムに当たるカードだけ強調される', () {
      final cards = run(
        springProfile,
        fortune(luckyColorId: 'coral_pink', category: ItemCategory.outfit),
      );

      expect(cards.where((c) => c.highlighted).map((c) => c.title), ['今日のコーデ']);
    });

    test('検索リンクに色名とカテゴリが入る', () {
      final cards = run(springProfile, fortune(luckyColorId: 'coral_pink'));
      final nail = cards.firstWhere((c) => c.title == '今日のネイル');

      final decoded = Uri.decodeComponent(nail.searchUrl.toString());
      expect(decoded, contains('コーラルピンク'));
      expect(decoded, contains('ネイルシール'));
    });
  });

  group('ラッキーカラーが似合う色と一致しないとき', () {
    test('ラッキーカラーはネイルで少量、主役は得意な色になる', () {
      final cards = run(springProfile, fortune(luckyColorId: 'royal_blue'));

      expect(cards, hasLength(3));

      final nail = cards.firstWhere((c) => c.title == '今日のネイル');
      expect(nail.color?.id, 'royal_blue');
      expect(nail.body, contains('ちょこっと'));

      final others = cards.where((c) => c.title != '今日のネイル');
      for (final card in others) {
        expect(card.color?.id, 'coral_pink', reason: '得意な色から選ばれること');
        expect(card.body, contains('主役は得意な色'));
      }
    });

    test('体型や容姿に触れる言い回しを使っていない', () {
      final cards = run(springProfile, fortune(luckyColorId: 'royal_blue'));
      const forbidden = ['痩せ', '太', '体型', 'カバー', '苦手'];

      for (final card in cards) {
        for (final word in forbidden) {
          expect(card.body, isNot(contains(word)), reason: card.title);
        }
      }
    });
  });

  group('データが欠けているとき', () {
    test('パーソナルカラー未診断なら、診断をうながすカードを1枚だけ返す', () {
      final cards = run(
        const UserProfile(),
        fortune(luckyColorId: 'coral_pink'),
      );

      expect(cards, hasLength(1));
      expect(cards.single.body, contains('パーソナルカラーを診断'));
      expect(cards.single.searchUrl, isNull);
    });

    test('ラッキーカラーIDが未知でも、得意な色だけで3枚返す', () {
      final cards = run(springProfile, fortune(luckyColorId: 'no_such_color'));

      expect(cards, hasLength(3));
      for (final card in cards) {
        expect(card.color?.id, 'coral_pink');
      }
    });
  });

  group('ルールの拡張', () {
    test('ルール関数を1つ足すだけでカードが増える', () {
      List<SuggestionCard> extraRule(SuggestionContext context) => const [
            SuggestionCard(ruleId: 'extra', title: '追加ルール', body: '本文'),
          ];

      final extended = SuggestionEngine(
        rules: [todayRecommend, extraRule],
      );
      final cards = extended.run(
        SuggestionContext(
          profile: springProfile,
          fortune: fortune(luckyColorId: 'coral_pink'),
          masters: masters,
        ),
      );

      expect(cards, hasLength(4));
      expect(cards.last.title, '追加ルール');
    });
  });
}
