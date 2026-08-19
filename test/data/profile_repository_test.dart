import 'package:flutter_test/flutter_test.dart';
import 'package:rakikara/data/profile_repository.dart';
import 'package:rakikara/models/enums.dart';
import 'package:rakikara/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const repository = ProfileRepository();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('未保存なら空のプロフィールが返る', () async {
    final profile = await repository.load();

    expect(profile.isEmpty, isTrue);
    expect(profile.isComplete, isFalse);
    expect(profile.zodiac, isNull);
  });

  test('保存した値が読み戻せる（＝再起動後も残る）', () async {
    final saved = UserProfile(
      personalColor: PersonalColorType.autumn,
      kokkaku: KokkakuType.natural,
      birthday: DateTime(2007, 11, 3),
    );

    await repository.save(saved);
    final loaded = await repository.load();

    expect(loaded, saved);
    expect(loaded.isComplete, isTrue);
    expect(loaded.zodiac, Zodiac.scorpio);
  });

  test('誕生日は日付だけが保存され、時刻は落ちる', () async {
    await repository.save(UserProfile(birthday: DateTime(2008, 5, 14, 23, 59)));

    expect((await repository.load()).birthday, DateTime(2008, 5, 14));
  });

  test('一部だけ保存された途中状態も扱える', () async {
    await repository.save(
      const UserProfile(personalColor: PersonalColorType.spring),
    );
    final loaded = await repository.load();

    expect(loaded.personalColor, PersonalColorType.spring);
    expect(loaded.kokkaku, isNull);
    expect(loaded.isComplete, isFalse);
  });

  test('値を null で上書きすると保存済みの値が消える', () async {
    await repository.save(
      const UserProfile(
        personalColor: PersonalColorType.spring,
        kokkaku: KokkakuType.wave,
      ),
    );
    await repository.save(const UserProfile(kokkaku: KokkakuType.wave));

    expect((await repository.load()).personalColor, isNull);
  });

  test('clear で全項目が消える', () async {
    await repository.save(
      UserProfile(
        personalColor: PersonalColorType.winter,
        kokkaku: KokkakuType.straight,
        birthday: DateTime(2009, 1, 1),
      ),
    );
    await repository.clear();

    expect((await repository.load()).isEmpty, isTrue);
  });

  test('壊れた保存値は未設定として扱い、例外にしない', () async {
    SharedPreferences.setMockInitialValues({
      ProfileRepository.personalColorKey: 'not_a_type',
      ProfileRepository.birthdayKey: 'ぐちゃぐちゃ',
    });

    final profile = await repository.load();

    expect(profile.personalColor, isNull);
    expect(profile.birthday, isNull);
  });
}
