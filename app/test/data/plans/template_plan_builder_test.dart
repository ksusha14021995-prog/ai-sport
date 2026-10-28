import 'dart:convert';
import 'dart:io';

import 'package:ai_sport/data/plans/template_plan_builder.dart';
import 'package:ai_sport/domain/models/onboarding.dart';
import 'package:ai_sport/domain/plans/plan_template.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../domain/plans/plan_test_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final templateFiles = Directory('assets/plans')
      .listSync()
      .whereType<File>()
      .where(
        (f) => TemplatePlanBuilder.isTemplateAsset(
          'assets/plans/${f.uri.pathSegments.last}',
        ),
      )
      .toList();

  group('shipped templates', () {
    test('there are at least 3', () {
      expect(templateFiles.length, greaterThanOrEqualTo(3));
    });

    for (final file in templateFiles) {
      final name = file.uri.pathSegments.last;
      test('$name parses, validates and id matches file name', () {
        final template = TemplatePlanBuilder.parseTemplate(
          file.readAsStringSync(),
          source: name,
        );
        expect('${template.id}.json', name);
        expect(
          PlanTemplate.fromJson(template.toJson()).toJson(),
          template.toJson(),
        );
      });
    }

    test('ids are unique', () {
      final ids = [
        for (final f in templateFiles)
          TemplatePlanBuilder.parseTemplate(
            f.readAsStringSync(),
            source: f.path,
          ).id,
      ];
      expect(ids.toSet(), hasLength(ids.length));
    });

    test('schema is valid JSON and lists every used exerciseId', () {
      final schema = jsonDecode(
        File(TemplatePlanBuilder.schemaFile).readAsStringSync(),
      ) as Map<String, dynamic>;
      final exerciseProps =
          ((schema['\$defs'] as Map<String, dynamic>)['exercise']
                  as Map<String, dynamic>)['properties']
              as Map<String, dynamic>;
      final allowed =
          ((exerciseProps['exerciseId'] as Map<String, dynamic>)['enum']
                  as List<dynamic>)
              .toSet();
      for (final f in templateFiles) {
        final t = TemplatePlanBuilder.parseTemplate(
          f.readAsStringSync(),
          source: f.path,
        );
        for (final e in t.exercises) {
          expect(allowed, contains(e.exerciseId), reason: t.id);
        }
      }
    });

    test('parse error names the source file', () {
      expect(
        () =>
            TemplatePlanBuilder.parseTemplate('{"id": "x"}', source: 'x.json'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            startsWith('x.json'),
          ),
        ),
      );
    });
  });

  group('TemplatePlanBuilder', () {
    test('default constructor loads templates from rootBundle', () async {
      final plan = await TemplatePlanBuilder().build(answers());
      expect(plan.templateId, 'tone-beginner');
      expect(plan.weeks, 8);
    });

    test(
      'loadFromBundle finds every shipped template and skips schema',
      () async {
        final templates = await TemplatePlanBuilder.loadFromBundle(rootBundle);
        expect(templates, hasLength(templateFiles.length));
      },
    );

    test('withTemplates uses given templates', () async {
      final plan = await TemplatePlanBuilder.withTemplates([template('only')])
          .build(answers(goals: {Goal.gainMass}));
      expect(plan.templateId, 'only');
    });

    test('throws StateError when screening failed', () async {
      final builder = TemplatePlanBuilder.withTemplates([template('only')]);
      await expectLater(
        builder.build(answers(screening: passedScreening().answer(3, true))),
        throwsStateError,
      );
    });
  });
}
