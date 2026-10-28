import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/models/onboarding.dart';
import '../../domain/models/training_plan.dart';
import '../../domain/plans/plan_rules.dart';
import '../../domain/plans/plan_template.dart';

/// Шаблоны Александры из `assets/plans/*.json` + правила [PlanRules].
class TemplatePlanBuilder implements PlanBuilder {
  static const templatesDir = 'assets/plans/';
  static const schemaFile = 'assets/plans/plan-template.schema.json';

  final Future<List<PlanTemplate>> Function() _loadTemplates;
  Future<List<PlanTemplate>>? _templates;

  TemplatePlanBuilder({AssetBundle? bundle})
    : _loadTemplates = (() => loadFromBundle(bundle ?? rootBundle));

  TemplatePlanBuilder.withTemplates(List<PlanTemplate> templates)
    : _loadTemplates = (() async => templates);

  @override
  Future<TrainingPlan> build(OnboardingAnswers answers) async =>
      PlanRules.build(await (_templates ??= _loadTemplates()), answers);

  static bool isTemplateAsset(String path) =>
      path.startsWith(templatesDir) &&
      path.endsWith('.json') &&
      path != schemaFile;

  static Future<List<PlanTemplate>> loadFromBundle(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final paths = manifest.listAssets().where(isTemplateAsset).toList()..sort();
    return [
      for (final path in paths)
        parseTemplate(await bundle.loadString(path), source: path),
    ];
  }

  static PlanTemplate parseTemplate(String json, {required String source}) {
    try {
      return switch (jsonDecode(json)) {
        Map<String, dynamic> map => PlanTemplate.fromJson(map),
        _ => throw const FormatException('ожидается JSON-объект'),
      };
    } on FormatException catch (e) {
      throw FormatException('$source: ${e.message}');
    }
  }
}
