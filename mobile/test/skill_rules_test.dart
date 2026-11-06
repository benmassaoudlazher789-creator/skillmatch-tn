import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/skills/domain/skill_rules.dart';

void main() {
  const existing = ['Dart', 'Flutter', 'Power BI'];

  group('clean', () {
    test('retire les espaces au début, à la fin et en double', () {
      expect(SkillRules.clean('  Docker  '), 'Docker');
      expect(SkillRules.clean('Power    BI'), 'Power BI');
      expect(SkillRules.clean('   '), '');
    });
  });

  group('validate', () {
    test('accepte une nouvelle compétence', () {
      expect(SkillRules.validate('Docker', existing), isNull);
      expect(SkillRules.validate('  Docker ', existing), isNull);
    });

    test('refuse un champ vide ou rempli d\'espaces', () {
      expect(SkillRules.validate('', existing), SkillRules.emptyError);
      expect(SkillRules.validate('    ', existing), SkillRules.emptyError);
    });

    test('refuse un doublon, sans tenir compte des majuscules', () {
      expect(
        SkillRules.validate('Flutter', existing),
        SkillRules.duplicateError,
      );
      expect(
        SkillRules.validate('flutter', existing),
        SkillRules.duplicateError,
      );
      expect(SkillRules.validate('DART', existing), SkillRules.duplicateError);
      // Les espaces en trop ne trompent pas la règle.
      expect(
        SkillRules.validate(' power   bi ', existing),
        SkillRules.duplicateError,
      );
    });

    test('accepte exactement 40 caractères, refuse 41', () {
      final forty = 'a' * SkillRules.maxLength;
      final fortyOne = 'a' * (SkillRules.maxLength + 1);
      expect(SkillRules.validate(forty, existing), isNull);
      expect(SkillRules.validate(fortyOne, existing), SkillRules.tooLongError);
    });

    test('la longueur est comptée après nettoyage', () {
      // 40 lettres entourées d'espaces : acceptées.
      final padded = '   ${'b' * SkillRules.maxLength}   ';
      expect(SkillRules.validate(padded, existing), isNull);
    });

    test('accepte tout dans une liste vide', () {
      expect(SkillRules.validate('Git', const []), isNull);
    });
  });

  test('le message de longueur cite la limite', () {
    expect(SkillRules.tooLongError, '40 caractères maximum.');
  });
}
