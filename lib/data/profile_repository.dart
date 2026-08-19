import 'package:shared_preferences/shared_preferences.dart';

import '../models/enums.dart';
import '../models/user_profile.dart';

/// プロフィールの端末ローカル保存。
///
/// 保存先は `shared_preferences` のみ。**ネットワークには一切出さない**
/// （`docs/SPEC.md` §5 / `CLAUDE.md` の「絶対に破らないルール」1）。
class ProfileRepository {
  const ProfileRepository();

  /// キー名は保存済みデータとの互換のため変更しない。
  static const String personalColorKey = 'profile.personal_color';
  static const String kokkakuKey = 'profile.kokkaku';
  static const String birthdayKey = 'profile.birthday';

  Future<UserProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    return UserProfile(
      personalColor: PersonalColorType.tryFromId(prefs.getString(personalColorKey)),
      kokkaku: KokkakuType.tryFromId(prefs.getString(kokkakuKey)),
      birthday: _parseBirthday(prefs.getString(birthdayKey)),
    );
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await _writeOrRemove(prefs, personalColorKey, profile.personalColor?.id);
    await _writeOrRemove(prefs, kokkakuKey, profile.kokkaku?.id);
    await _writeOrRemove(prefs, birthdayKey, _formatBirthday(profile.birthday));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(personalColorKey);
    await prefs.remove(kokkakuKey);
    await prefs.remove(birthdayKey);
  }

  Future<void> _writeOrRemove(SharedPreferences prefs, String key, String? value) {
    return value == null ? prefs.remove(key) : prefs.setString(key, value);
  }

  /// 誕生日は時刻を持たないので `YYYY-MM-DD` で保存する。
  static String? _formatBirthday(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// 壊れた値が入っていたら「未設定」として扱う。
  /// 起動できなくなるより、診断をやり直してもらうほうがまし。
  static DateTime? _parseBirthday(String? raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }
}
