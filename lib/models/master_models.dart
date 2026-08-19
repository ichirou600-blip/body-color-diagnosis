import 'enums.dart';

/// JSONの形が想定と違うときに投げる例外。
///
/// どのファイルのどこが悪いのかをメッセージに含める。
/// 本コンテンツを投入したときの切り分けを速くするため。
class MasterFormatException implements Exception {
  MasterFormatException(this.file, this.message);

  final String file;
  final String message;

  @override
  String toString() => 'MasterFormatException($file): $message';
}

/// JSONの雑多な型チェックをまとめたヘルパ。
class JsonReader {
  JsonReader(this.file);

  final String file;

  Never _fail(String message) => throw MasterFormatException(file, message);

  Map<String, dynamic> asMap(Object? value, String where) {
    if (value is Map<String, dynamic>) return value;
    _fail('$where はオブジェクトである必要があります（実際: ${value.runtimeType}）');
  }

  List<Map<String, dynamic>> asMapList(Object? value, String where) {
    if (value is! List) {
      _fail('$where は配列である必要があります（実際: ${value.runtimeType}）');
    }
    return [
      for (var i = 0; i < value.length; i++) asMap(value[i], '$where[$i]'),
    ];
  }

  String asString(Map<String, dynamic> map, String key, String where) {
    final value = map[key];
    if (value is String && value.isNotEmpty) return value;
    _fail('$where の "$key" は空でない文字列である必要があります');
  }

  List<String> asStringList(Map<String, dynamic> map, String key, String where) {
    final value = map[key];
    if (value == null) return const [];
    if (value is! List) _fail('$where の "$key" は配列である必要があります');
    return [
      for (final item in value)
        if (item is String) item else _fail('$where の "$key" に文字列でない要素があります'),
    ];
  }

  T asEnum<T>(String? id, T? Function(String?) parse, String where) {
    final parsed = parse(id);
    if (parsed != null) return parsed;
    _fail('$where のID "$id" は未知の値です（docs/DATA_SCHEMA.md 参照）');
  }
}

/// `color_master.json` の1色。
class ColorItem {
  const ColorItem({
    required this.id,
    required this.name,
    required this.hex,
    required this.pcTypes,
  });

  final String id;
  final String name;
  final String hex;
  final List<PersonalColorType> pcTypes;

  static final RegExp _hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

  factory ColorItem.fromJson(Map<String, dynamic> json, JsonReader reader, String where) {
    final hex = reader.asString(json, 'hex', where);
    if (!_hexPattern.hasMatch(hex)) {
      throw MasterFormatException(reader.file, '$where の "hex" は #RRGGBB 形式である必要があります: $hex');
    }
    return ColorItem(
      id: reader.asString(json, 'id', where),
      name: reader.asString(json, 'name', where),
      hex: hex,
      pcTypes: [
        for (final id in reader.asStringList(json, 'pc_types', where))
          reader.asEnum(id, PersonalColorType.tryFromId, '$where の "pc_types"'),
      ],
    );
  }

  /// `#RRGGBB` を `Color` の値（0xFFRRGGBB）に変換する。
  int get argb => 0xFF000000 | int.parse(hex.substring(1), radix: 16);
}

/// `type_attributes.json` の1タイプ。PCタイプ・骨格タイプで共用する。
class TypeAttribute {
  const TypeAttribute({
    required this.id,
    required this.colorIds,
    required this.materials,
    required this.keywords,
    required this.description,
  });

  final String id;
  final List<String> colorIds;
  final List<String> materials;
  final List<String> keywords;
  final String description;

  factory TypeAttribute.fromJson(Map<String, dynamic> json, JsonReader reader, String where) {
    return TypeAttribute(
      id: reader.asString(json, 'id', where),
      colorIds: reader.asStringList(json, 'color_ids', where),
      materials: reader.asStringList(json, 'materials', where),
      keywords: reader.asStringList(json, 'keywords', where),
      description: reader.asString(json, 'description', where),
    );
  }
}

/// `pc_x_kokkaku.json` の1件。
class PcKokkakuStyle {
  const PcKokkakuStyle({
    required this.pcType,
    required this.kokkakuType,
    required this.styleText,
  });

  final PersonalColorType pcType;
  final KokkakuType kokkakuType;
  final String styleText;

  factory PcKokkakuStyle.fromJson(Map<String, dynamic> json, JsonReader reader, String where) {
    return PcKokkakuStyle(
      pcType: reader.asEnum(
        json['pc_type'] as String?,
        PersonalColorType.tryFromId,
        '$where の "pc_type"',
      ),
      kokkakuType: reader.asEnum(
        json['kokkaku_type'] as String?,
        KokkakuType.tryFromId,
        '$where の "kokkaku_type"',
      ),
      styleText: reader.asString(json, 'style_text', where),
    );
  }
}

/// `compatibility.json` の1件。星座の組は順序を持たない。
class CompatibilityEntry {
  const CompatibilityEntry({
    required this.zodiacA,
    required this.zodiacB,
    required this.text,
  });

  final Zodiac zodiacA;
  final Zodiac zodiacB;
  final String text;

  factory CompatibilityEntry.fromJson(Map<String, dynamic> json, JsonReader reader, String where) {
    return CompatibilityEntry(
      zodiacA: reader.asEnum(json['zodiac_a'] as String?, Zodiac.tryFromId, '$where の "zodiac_a"'),
      zodiacB: reader.asEnum(json['zodiac_b'] as String?, Zodiac.tryFromId, '$where の "zodiac_b"'),
      text: reader.asString(json, 'text', where),
    );
  }

  /// 順序を無視した検索キー。`(a,b)` と `(b,a)` が同じ値になる。
  static String pairKey(Zodiac a, Zodiac b) {
    final ids = [a.id, b.id]..sort();
    return ids.join('|');
  }

  String get key => pairKey(zodiacA, zodiacB);
}

/// `questions.json` の選択肢。`scores` のキーはタイプid。
class Choice {
  const Choice({required this.id, required this.text, required this.scores});

  final String id;
  final String text;
  final Map<String, int> scores;

  factory Choice.fromJson(
    Map<String, dynamic> json,
    JsonReader reader,
    String where,
    Set<String> allowedTypeIds,
  ) {
    final rawScores = json['scores'];
    final scores = <String, int>{};
    if (rawScores != null) {
      final map = reader.asMap(rawScores, '$where の "scores"');
      map.forEach((typeId, value) {
        if (!allowedTypeIds.contains(typeId)) {
          throw MasterFormatException(
            reader.file,
            '$where の "scores" に未知のタイプid "$typeId" があります（許可: ${allowedTypeIds.join(", ")}）',
          );
        }
        if (value is! int) {
          throw MasterFormatException(reader.file, '$where の "scores.$typeId" は整数である必要があります');
        }
        scores[typeId] = value;
      });
    }
    return Choice(
      id: reader.asString(json, 'id', where),
      text: reader.asString(json, 'text', where),
      scores: Map.unmodifiable(scores),
    );
  }
}

/// `questions.json` の1問。
class Question {
  const Question({required this.id, required this.text, required this.choices});

  final String id;
  final String text;
  final List<Choice> choices;

  factory Question.fromJson(
    Map<String, dynamic> json,
    JsonReader reader,
    String where,
    Set<String> allowedTypeIds,
  ) {
    final choiceMaps = reader.asMapList(json['choices'], '$where の "choices"');
    if (choiceMaps.length < 2) {
      throw MasterFormatException(reader.file, '$where の選択肢は2つ以上必要です');
    }
    return Question(
      id: reader.asString(json, 'id', where),
      text: reader.asString(json, 'text', where),
      choices: [
        for (var i = 0; i < choiceMaps.length; i++)
          Choice.fromJson(choiceMaps[i], reader, '$where の choices[$i]', allowedTypeIds),
      ],
    );
  }
}
