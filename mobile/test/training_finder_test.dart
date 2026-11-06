import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/trainings/data/sample_trainings.dart';
import 'package:skillmatch_tn/features/trainings/domain/training.dart';
import 'package:skillmatch_tn/features/trainings/domain/training_finder.dart';

void main() {
  /// Petite fabrique de formations fictives, propre aux tests.
  Training training(
    String id, {
    String skill = 'Docker',
    String title = 'Titre',
    TrainingLevel level = TrainingLevel.debutant,
    int hours = 2,
  }) => Training(
    id: id,
    skill: skill,
    title: title,
    level: level,
    hours: hours,
    type: TrainingType.tutoriel,
  );

  test('Durée affichée : « environ 3 h »', () {
    expect(training('a', hours: 3).durationLabel, 'environ 3 h');
  });

  group('Recherche', () {
    final catalog = [
      training('docker', skill: 'Docker'),
      training('react', skill: 'React'),
    ];

    test('Une compétence connue renvoie ses formations', () {
      final found = TrainingFinder.forSkill('Docker', catalog);
      expect(found.map((t) => t.id), ['docker']);
    });

    test('Une compétence inconnue renvoie une liste vide', () {
      expect(TrainingFinder.forSkill('Linux', catalog), isEmpty);
    });

    test('Majuscules et espaces en trop ignorés', () {
      expect(TrainingFinder.forSkill('  docker ', catalog), hasLength(1));
      expect(TrainingFinder.forSkill('REACT', catalog), hasLength(1));
    });

    test('Catalogue vide : aucune formation', () {
      expect(TrainingFinder.forSkill('Docker', []), isEmpty);
    });
  });

  test('Tri : niveau, puis durée, puis titre', () {
    final catalog = [
      training('avance', level: TrainingLevel.avance, hours: 1),
      training('inter', level: TrainingLevel.intermediaire, hours: 1),
      training('deb-long', hours: 9),
      training('deb-court-b', title: 'B', hours: 2),
      training('deb-court-a', title: 'a', hours: 2),
    ];

    final found = TrainingFinder.forSkill('Docker', catalog);

    expect(found.map((t) => t.id), [
      'deb-court-a',
      'deb-court-b',
      'deb-long',
      'inter',
      'avance',
    ]);
  });

  group("Formations d'exemple", () {
    test('Windows, Linux et Réseaux n\'ont aucune formation (cas vide)', () {
      for (final skill in ['Windows', 'Linux', 'Réseaux']) {
        expect(
          TrainingFinder.forSkill(skill, sampleTrainings),
          isEmpty,
          reason: skill,
        );
      }
    });

    test('Docker a des formations', () {
      expect(TrainingFinder.forSkill('Docker', sampleTrainings), isNotEmpty);
    });

    test('Identifiants uniques', () {
      final ids = sampleTrainings.map((t) => t.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  });
}
