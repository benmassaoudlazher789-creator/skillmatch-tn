import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/core/theme/widgets/skill_chip.dart';
import 'package:skillmatch_tn/features/offers/data/sample_offers.dart';
import 'package:skillmatch_tn/features/offers/domain/offer.dart';
import 'package:skillmatch_tn/features/offers/presentation/offers_screen.dart';
import 'package:skillmatch_tn/features/offers/presentation/widgets/offer_card.dart';

void main() {
  // Compétences et offres fictives, propres aux tests : ils ne dépendent
  // pas des offres d'exemple de l'application.
  const skills = ['Dart', 'Flutter', 'SQL'];
  const offers = [
    // 70 × 2/2 + 30 × 0/1 = 70 %
    Offer(
      id: 'stage',
      title: 'Stage Flutter',
      company: 'Entreprise test A',
      city: 'Ville A',
      type: OfferType.stage,
      requiredSkills: ['Dart', 'Flutter'],
      preferredSkills: ['Docker'],
    ),
    // 1/2 requise, pas de souhaitées = 50 %
    Offer(
      id: 'web',
      title: 'Emploi web',
      company: 'Entreprise test B',
      city: 'Ville B',
      type: OfferType.emploi,
      requiredSkills: ['JavaScript', 'SQL'],
    ),
    // 70 × 0/1 + 30 × 1/1 = 30 %
    Offer(
      id: 'pfe',
      title: 'PFE données',
      company: 'Entreprise test C',
      city: 'Ville C',
      type: OfferType.pfe,
      requiredSkills: ['Python'],
      preferredSkills: ['SQL'],
    ),
    // Tout correspond = 100 %
    Offer(
      id: 'complet',
      title: 'Emploi complet',
      company: 'Entreprise test D',
      city: 'Ville D',
      type: OfferType.emploi,
      requiredSkills: ['Dart'],
      preferredSkills: ['SQL'],
    ),
  ];

  // Même principe que les autres tests : MaterialApp sans AppTheme, car
  // google_fonts n'a pas Internet pendant les tests.
  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Offer> list = offers,
    bool useSampleOffers = false,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: useSampleOffers
            ? const OffersScreen(skills: skills)
            : OffersScreen(skills: skills, offers: list),
      ),
    );
  }

  Finder card(String id) => find.byKey(OffersScreen.cardKey(id));

  /// Puce [label] de la sorte [kind], dans la carte [id].
  Finder chip(String id, String label, SkillChipKind kind) => find.descendant(
    of: card(id),
    matching: find.byWidgetPredicate(
      (w) => w is SkillChip && w.label == label && w.kind == kind,
    ),
  );

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  testWidgets('Affichage : titre, bandeaux, une carte par offre', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Offres'), findsOneWidget); // barre du haut
    expect(find.text(OffersScreen.heading), findsOneWidget);
    expect(find.text(OffersScreen.exampleBanner), findsOneWidget);
    expect(find.text(OffersScreen.scoreInfo), findsOneWidget);
    for (final o in offers) {
      expect(card(o.id), findsOneWidget, reason: o.id);
    }
  });

  testWidgets('Tri : du meilleur score au plus faible', (tester) async {
    await pumpScreen(tester);

    double top(String id) => tester.getTopLeft(card(id)).dy;
    expect(top('complet'), lessThan(top('stage')));
    expect(top('stage'), lessThan(top('web')));
    expect(top('web'), lessThan(top('pfe')));

    expect(
      find.descendant(of: card('complet'), matching: find.text('100 %')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card('stage'), matching: find.text('70 %')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card('web'), matching: find.text('50 %')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: card('pfe'), matching: find.text('30 %')),
      findsOneWidget,
    );
  });

  testWidgets('Le score est expliqué sur chaque carte', (tester) async {
    await pumpScreen(tester);

    expect(
      find.descendant(
        of: card('stage'),
        matching: find.text(
          'Requises : 2 sur 2 (70 % du score) · Souhaitées : 0 sur 1 (30 %)',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card('web'),
        matching: find.text('Requises : 1 sur 2 (100 % du score)'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Puces vertes pour les acquises, rouges pour les manquantes', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(chip('stage', 'Dart', SkillChipKind.acquired), findsOneWidget);
    expect(chip('stage', 'Flutter', SkillChipKind.acquired), findsOneWidget);
    expect(chip('stage', 'Docker', SkillChipKind.missing), findsOneWidget);
    expect(chip('stage', 'Docker', SkillChipKind.acquired), findsNothing);

    expect(chip('web', 'SQL', SkillChipKind.acquired), findsOneWidget);
    expect(chip('web', 'JavaScript', SkillChipKind.missing), findsOneWidget);

    // Offre à 100 % : aucune puce rouge, une phrase à la place.
    expect(
      find.descendant(
        of: card('complet'),
        matching: find.byWidgetPredicate(
          (w) => w is SkillChip && w.kind == SkillChipKind.missing,
        ),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: card('complet'),
        matching: find.text('aucune compétence manquante'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Toucher une compétence manquante affiche le message', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tapVisible(tester, chip('stage', 'Docker', SkillChipKind.missing));

    expect(
      find.text(OffersScreen.trainingSoonMessage('Docker')),
      findsOneWidget,
    );
  });

  testWidgets('Filtres : Tout, Emplois, Stages, PFE', (tester) async {
    await pumpScreen(tester);

    await tapVisible(tester, find.byKey(OffersScreen.filterKey(OfferType.pfe)));
    expect(card('pfe'), findsOneWidget);
    expect(card('stage'), findsNothing);
    expect(card('web'), findsNothing);
    expect(card('complet'), findsNothing);

    await tapVisible(
      tester,
      find.byKey(OffersScreen.filterKey(OfferType.emploi)),
    );
    expect(card('complet'), findsOneWidget);
    expect(card('web'), findsOneWidget);
    expect(card('pfe'), findsNothing);
    // Le filtre garde l'ordre du score.
    expect(
      tester.getTopLeft(card('complet')).dy,
      lessThan(tester.getTopLeft(card('web')).dy),
    );

    await tapVisible(tester, find.byKey(OffersScreen.filterKey(null)));
    for (final o in offers) {
      expect(card(o.id), findsOneWidget, reason: o.id);
    }
  });

  testWidgets('Filtre sans offre : un message le dit', (tester) async {
    await pumpScreen(tester, list: [offers.first]); // un seul stage

    await tapVisible(tester, find.byKey(OffersScreen.filterKey(OfferType.pfe)));

    expect(find.text(OffersScreen.emptyFilter), findsOneWidget);
    expect(find.byType(OfferCard), findsNothing);
  });

  testWidgets('Offres d\'exemple : chaque carte porte le badge', (
    tester,
  ) async {
    await pumpScreen(tester, useSampleOffers: true);

    expect(find.byType(OfferCard), findsNWidgets(sampleOffers.length));
    expect(
      find.text(OfferCard.sampleBadge),
      findsNWidgets(sampleOffers.length),
    );
    // Les entreprises sont inventées et le disent.
    for (final o in sampleOffers) {
      expect(o.company, contains('Exemple'), reason: o.id);
    }
  });

  testWidgets('Petit écran et texte agrandi : rien ne déborde', (tester) async {
    // Un débordement (« RenderFlex overflowed ») ferait échouer ce test.
    await pumpScreen(
      tester,
      useSampleOffers: true,
      size: const Size(320, 640),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Offres respecte les règles de contenu', (tester) async {
    await pumpScreen(tester, useSampleOffers: true);

    // Mots interdits par CLAUDE.md (racines, pour couvrir les accords).
    for (final word in [
      'vérifi',
      'Vérifi',
      'certifi',
      'prouv',
      'passeport',
      'défi',
      'chiffr',
      'robot',
    ]) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
    // Éléments de la maquette volontairement retirés.
    for (final removed in ['Source', 'TND', 'Détails', 'Match', 'maximiser']) {
      expect(find.textContaining(removed), findsNothing, reason: removed);
    }
  });
}
