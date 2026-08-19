import 'enums.dart';

/// 端末ローカルにだけ保存するユーザープロフィール。
///
/// **サーバーに送信してはいけない**（`docs/SPEC.md` §5 / `CLAUDE.md`）。
/// 診断途中は各項目が null になりうるので、すべて optional。
class UserProfile {
  const UserProfile({this.personalColor, this.kokkaku, this.birthday});

  final PersonalColorType? personalColor;
  final KokkakuType? kokkaku;
  final DateTime? birthday;

  /// 誕生日から算出した星座。誕生日未設定なら null。
  Zodiac? get zodiac {
    final birthday = this.birthday;
    return birthday == null ? null : Zodiac.fromDate(birthday);
  }

  /// 診断が一通り終わっているか。
  bool get isComplete =>
      personalColor != null && kokkaku != null && birthday != null;

  bool get isEmpty =>
      personalColor == null && kokkaku == null && birthday == null;

  UserProfile copyWith({
    PersonalColorType? personalColor,
    KokkakuType? kokkaku,
    DateTime? birthday,
  }) {
    return UserProfile(
      personalColor: personalColor ?? this.personalColor,
      kokkaku: kokkaku ?? this.kokkaku,
      birthday: birthday ?? this.birthday,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserProfile &&
      other.personalColor == personalColor &&
      other.kokkaku == kokkaku &&
      other.birthday == birthday;

  @override
  int get hashCode => Object.hash(personalColor, kokkaku, birthday);

  @override
  String toString() =>
      'UserProfile(personalColor: ${personalColor?.id}, '
      'kokkaku: ${kokkaku?.id}, birthday: ${birthday?.toIso8601String()})';
}
