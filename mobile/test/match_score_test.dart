import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/offers/domain/match_score.dart';
import 'package:skillmatch_tn/features/offers/domain/offer.dart';

void main() {
  /// Petite fabrique d'offres fictives, propre aux tests.
  Offer offer({
    String id = 't',
    String title = 'Offre test',
    List<String> required = const [],
    List<String> preferred = const [],
  }) => Offer(
    id: id,
    title: title,
    company: 'Entreprise test',
    city: 'Ville test',
    type: OfferType.stage,
    requiredSkills: required,
    preferredSkills: preferred,
  );

  final fullOffer = offer(
    required: ['Dart', 'Flutter', 'Git'],
    preferred: ['Docker', 'Figma'],
  );

  group('Score', () {
    test('0 % quand aucune compétence ne correspond', () {
      final r = MatchScore.compute(fullOffer, ['Python', 'Excel']);
      expect(r.percent, 0);
      expect(r.acquired, isEmpty);
      expect(r.missing, ['Dart', 'Flutter', 'Git', 'Docker', 'Figma']);
    });

    test('0 % avec une liste de compétences vide', () {
      expect(MatchScore.compute(fullOffer, []).percent, 0);
    });

    test('100 % quand tout correspond', () {
      final r = MatchScore.compute(fullOffer, [
        'Dart',
        'Flutter',
        'Git',
        'Docker',
        'Figma',
      ]);
      expect(r.percent, 100);
      expect(r.missing, isEmpty);
    });

    test('Toutes les requises, aucune souhaitée : 70 %', () {
      final r = MatchScore.compute(fullOffer, ['Dart', 'Flutter', 'Git']);
      expect(r.percent, 70);
      expect(r.missing, ['Docker', 'Figma']);
    });

    test('Aucune requise, toutes les souhaitées : 30 %', () {
      expect(MatchScore.compute(fullOffer, ['Docker', 'Figma']).percent, 30);
    });

    test('Cas mélangé, arrondi vers le bas', () {
      // 70 × 2/3 + 30 × 1/2 = 46,67 + 15 = 61,67 → 61
      final r = MatchScore.compute(fullOffer, ['Dart', 'Git', 'Figma']);
      expect(r.percent, 61);
      expect(r.requiredAcquired, ['Dart', 'Git']);
      expect(r.requiredMissing, ['Flutter']);
      expect(r.preferredAcquired, ['Figma']);
      expect(r.preferredMissing, ['Docker']);
    });

    test("Jamais 100 % s'il manque une compétence", () {
      // 70 × 1 + 30 × 99/100 = 99,7 → 99, pas 100.
      final many = offer(
        required: ['A'],
        preferred: [for (var i = 0; i < 100; i++) 'S$i'],
      );
      final skills = ['A', for (var i = 0; i < 99; i++) 'S$i'];
      expect(MatchScore.compute(many, skills).percent, 99);
    });

    test('Offre sans souhaitées : les requises comptent pour 100 %', () {
      final r = MatchScore.compute(offer(required: ['Dart', 'SQL']), ['Dart']);
      expect(r.percent, 50);
      expect(r.explanation, 'Requises : 1 sur 2 (100 % du score)');
    });

    test('Offre sans aucune compétence : 0 %, sans erreur', () {
      final r = MatchScore.compute(offer(), ['Dart']);
      expect(r.percent, 0);
      expect(r.explanation, 'Aucune compétence indiquée pour cette offre.');
    });

    test('Majuscules et espaces en trop ignorés', () {
      final r = MatchScore.compute(fullOffer, [
        'dart',
        'FLUTTER',
        '  git  ',
        'fig  ma', // espace au milieu : ce n'est pas « Figma »
      ]);
      expect(r.percent, 70);
      // Les puces gardent l'écriture de l'offre.
      expect(r.acquired, ['Dart', 'Flutter', 'Git']);
    });

    test('Les accents comptent (limite assumée)', () {
      final r = MatchScore.compute(offer(required: ['Réseaux']), ['Reseaux']);
      expect(r.percent, 0);
    });
  });

  test('Explication : poids et compteurs', () {
    final r = MatchScore.compute(fullOffer, ['Dart', 'Git', 'Figma']);
    expect(
      r.explanation,
      'Requises : 2 sur 3 (70 % du score) · Souhaitées : 1 sur 2 (30 %)',
    );
  });

  group('Tri', () {
    test('Du meilleur score au plus faible', () {
      final offers = [
        offer(id: 'faible', title: 'C', required: ['X', 'Y']),
        offer(id: 'fort', title: 'A', required: ['Dart']),
        offer(id: 'moyen', title: 'B', required: ['Dart', 'Y']),
      ];
      final ranked = MatchScore.rank(offers, ['Dart']);
      expect(ranked.map((r) => r.offer.id), ['fort', 'moyen', 'faible']);
      expect(ranked.map((r) => r.percent), [100, 50, 0]);
    });

    test('À score égal, ordre alphabétique du titre', () {
      final offers = [
        offer(id: 'z', title: 'zèbre', required: ['Dart']),
        offer(id: 'a', title: 'Avion', required: ['Dart']),
        offer(id: 'm', title: 'Maison', required: ['Dart']),
      ];
      final ranked = MatchScore.rank(offers, ['Dart']);
      expect(ranked.map((r) => r.offer.id), ['a', 'm', 'z']);
    });

    test('Liste vide : aucun résultat', () {
      expect(MatchScore.rank([], ['Dart']), isEmpty);
    });
  });
}
