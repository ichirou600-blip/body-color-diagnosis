import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/enums.dart';
import '../models/master_models.dart';
import 'master_data.dart';

/// `assets/` の静的JSONを読み込んで [MasterData] を組み立てる。
///
/// 想定と違う形のJSONは [MasterFormatException] で弾く。黙って握りつぶすと
/// 本コンテンツ投入時に「なぜか画面が空」という調査しづらい壊れ方をするため。
/// 検証内容は `docs/DATA_SCHEMA.md` の「コードが起動時に検証すること」。
class MasterRepository {
  const MasterRepository({this.bundle});

  /// 差し替え用。null なら `rootBundle` を使う。
  final AssetBundle? bundle;

  static const String colorMasterPath = 'assets/color_master.json';
  static const String typeAttributesPath = 'assets/type_attributes.json';
  static const String pcXKokkakuPath = 'assets/pc_x_kokkaku.json';
  static const String compatibilityPath = 'assets/compatibility.json';
  static const String questionsPath = 'assets/questions.json';

  AssetBundle get _assets => bundle ?? rootBundle;

  Future<MasterData> load() async {
    final sources = <String, String>{};
    for (final path in const [
      colorMasterPath,
      typeAttributesPath,
      pcXKokkakuPath,
      compatibilityPath,
      questionsPath,
    ]) {
      sources[path] = await _assets.loadString(path);
    }
    return parse(sources);
  }

  /// 読み込み済みのJSON文字列から組み立てる。テストから直接呼べるようにしてある。
  MasterData parse(Map<String, String> sources) {
    final colors = _parseColors(sources[colorMasterPath]!);
    final colorIds = {for (final color in colors) color.id};

    final attributes = _parseTypeAttributes(sources[typeAttributesPath]!, colorIds);
    final styles = _parsePcXKokkaku(sources[pcXKokkakuPath]!);
    final compatibility = _parseCompatibility(sources[compatibilityPath]!);
    final questions = _parseQuestions(sources[questionsPath]!);

    return MasterData(
      colors: colors,
      personalColorAttributes: attributes.personalColors,
      kokkakuAttributes: attributes.kokkaku,
      pcKokkakuStyles: styles,
      compatibilityEntries: compatibility,
      personalColorQuestions: questions.personalColor,
      kokkakuQuestions: questions.kokkaku,
    );
  }

  Map<String, dynamic> _decodeRoot(String source, JsonReader reader) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw MasterFormatException(reader.file, 'JSONとして読めません: ${error.message}');
    }
    return reader.asMap(decoded, 'ルート');
  }

  List<ColorItem> _parseColors(String source) {
    final reader = JsonReader(colorMasterPath);
    final root = _decodeRoot(source, reader);
    final items = reader.asMapList(root['colors'], '"colors"');
    final colors = [
      for (var i = 0; i < items.length; i++)
        ColorItem.fromJson(items[i], reader, 'colors[$i]'),
    ];
    final seen = <String>{};
    for (final color in colors) {
      if (!seen.add(color.id)) {
        throw MasterFormatException(colorMasterPath, '色ID "${color.id}" が重複しています');
      }
    }
    return colors;
  }

  ({
    Map<PersonalColorType, TypeAttribute> personalColors,
    Map<KokkakuType, TypeAttribute> kokkaku,
  }) _parseTypeAttributes(String source, Set<String> colorIds) {
    final reader = JsonReader(typeAttributesPath);
    final root = _decodeRoot(source, reader);

    TypeAttribute readOne(Map<String, dynamic> json, String where) {
      final attribute = TypeAttribute.fromJson(json, reader, where);
      for (final colorId in attribute.colorIds) {
        if (!colorIds.contains(colorId)) {
          throw MasterFormatException(
            typeAttributesPath,
            '$where の "color_ids" にある "$colorId" が color_master.json にありません',
          );
        }
      }
      return attribute;
    }

    final pcItems = reader.asMapList(root['personal_colors'], '"personal_colors"');
    final pcAttributes = <PersonalColorType, TypeAttribute>{};
    for (var i = 0; i < pcItems.length; i++) {
      final where = 'personal_colors[$i]';
      final attribute = readOne(pcItems[i], where);
      final type = reader.asEnum(attribute.id, PersonalColorType.tryFromId, where);
      if (pcAttributes.containsKey(type)) {
        throw MasterFormatException(typeAttributesPath, 'PCタイプ "${type.id}" が重複しています');
      }
      pcAttributes[type] = attribute;
    }

    final kkItems = reader.asMapList(root['kokkaku'], '"kokkaku"');
    final kkAttributes = <KokkakuType, TypeAttribute>{};
    for (var i = 0; i < kkItems.length; i++) {
      final where = 'kokkaku[$i]';
      final attribute = readOne(kkItems[i], where);
      final type = reader.asEnum(attribute.id, KokkakuType.tryFromId, where);
      if (kkAttributes.containsKey(type)) {
        throw MasterFormatException(typeAttributesPath, '骨格タイプ "${type.id}" が重複しています');
      }
      kkAttributes[type] = attribute;
    }

    // ここだけは件数を検証する。1つでも欠けると診断結果を表示できないため。
    if (pcAttributes.length != PersonalColorType.values.length) {
      throw MasterFormatException(
        typeAttributesPath,
        '"personal_colors" は${PersonalColorType.values.length}件必要です（実際: ${pcAttributes.length}件）',
      );
    }
    if (kkAttributes.length != KokkakuType.values.length) {
      throw MasterFormatException(
        typeAttributesPath,
        '"kokkaku" は${KokkakuType.values.length}件必要です（実際: ${kkAttributes.length}件）',
      );
    }

    return (personalColors: pcAttributes, kokkaku: kkAttributes);
  }

  List<PcKokkakuStyle> _parsePcXKokkaku(String source) {
    final reader = JsonReader(pcXKokkakuPath);
    final root = _decodeRoot(source, reader);
    final items = reader.asMapList(root['entries'], '"entries"');
    final styles = <PcKokkakuStyle>[];
    final seen = <String>{};
    for (var i = 0; i < items.length; i++) {
      final style = PcKokkakuStyle.fromJson(items[i], reader, 'entries[$i]');
      final key = '${style.pcType.id}|${style.kokkakuType.id}';
      if (!seen.add(key)) {
        throw MasterFormatException(pcXKokkakuPath, '組み合わせ "$key" が重複しています');
      }
      styles.add(style);
    }
    return styles;
  }

  List<CompatibilityEntry> _parseCompatibility(String source) {
    final reader = JsonReader(compatibilityPath);
    final root = _decodeRoot(source, reader);
    final items = reader.asMapList(root['entries'], '"entries"');
    final entries = <CompatibilityEntry>[];
    final seen = <String>{};
    for (var i = 0; i < items.length; i++) {
      final entry = CompatibilityEntry.fromJson(items[i], reader, 'entries[$i]');
      if (!seen.add(entry.key)) {
        throw MasterFormatException(
          compatibilityPath,
          '星座の組 "${entry.key}" が重複しています（順序違いも同じ組として扱います）',
        );
      }
      entries.add(entry);
    }
    return entries;
  }

  ({List<Question> personalColor, List<Question> kokkaku}) _parseQuestions(String source) {
    final reader = JsonReader(questionsPath);
    final root = _decodeRoot(source, reader);

    List<Question> readSection(String key, Set<String> allowedTypeIds) {
      final items = reader.asMapList(root[key], '"$key"');
      final questions = <Question>[];
      final seen = <String>{};
      for (var i = 0; i < items.length; i++) {
        final question = Question.fromJson(items[i], reader, '$key[$i]', allowedTypeIds);
        if (!seen.add(question.id)) {
          throw MasterFormatException(questionsPath, '設問ID "${question.id}" が重複しています');
        }
        questions.add(question);
      }
      return questions;
    }

    return (
      personalColor: readSection(
        'personal_color',
        {for (final value in PersonalColorType.values) value.id},
      ),
      kokkaku: readSection(
        'kokkaku',
        {for (final value in KokkakuType.values) value.id},
      ),
    );
  }
}
