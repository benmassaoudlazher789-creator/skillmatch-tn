import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/core/theme/widgets/skill_chip.dart';
import 'package:skillmatch_tn/features/auth/domain/auth_failure.dart';
import 'package:skillmatch_tn/features/offers/domain/offer.dart';
import 'package:skillmatch_tn/features/offers/domain/offers_failure.dart';
import 'package:skillmatch_tn/features/offers/presentation/offers_screen.dart';
import 'package:skillmatch_tn/features/offers/presentation/widgets/offer_card.dart';
import 'package:skillmatch_tn/features/trainings/presentation/trainings_screen.dart';
import 'package:skillmatch_tn/features/trainings/presentation/widgets/training_card.dart';

import 'support/fake_offers.dart';

void main() {
  // Compétences et offres fictives, propres aux tests. Les scores et les
  // listes sont ceux qu'aurait renvoyés le serveur : l'écran ne calcule rien.
  const skills = ['Dart', 'Flutter', 'SQL'];
  final offers = [
    fakeOffer(
      id: 'complet',
      title: 'Emploi complet',
      type: OfferType.emploi,
      score: 100,
      explanation:
          'Requises : 1 sur 1 (70 % du score) · Souhaitées : 1 sur 1 (30 %)',
      requiredAcquired: ['Dart'],
      preferredAcquired: ['SQL'],
    ),
    fakeOffer(
      id: 'stage',
      title: 'Stage Flutter',
      isSample: true,
      score: 70,
      explanation:
          'Requises : 2 sur 2 (70 % du score) · Souhaitées : 0 sur 1 (30 %)',
      requiredAcquired: ['Dart', 'Flutter'],
      preferredMissing: ['Docker'],
    ),
    fakeOffer(
      id: 'web',
      title: 'Emploi web',
      type: OfferType.emploi,
      score: 50,
      explanation: 'Requises : 1 sur 2 (100 % du score)',
      requiredAcquired: ['SQL'],
      requiredMissing: ['JavaScript'],
    ),
    fakeOffer(
      id: 'pfe',
      title: 'PFE données',
      type: OfferType.pfe,
      score: 30,
      requiredMissing: ['Python'],
      preferredAcquired: ['SQL'],
    ),
  ];

  late FakeOffersApi api;

  // Même principe que les autres tests : MaterialApp sans AppTheme, car
  // google_fonts n'a pas Internet pendant les tests.
  // [onFetch] remplace la réponse du serveur : aucun appel réseau réel.
  Future<void> pumpScreen(
    WidgetTester tester, {
    List<Offer>? list,
    Future<List<Offer>> Function()? onFetch,
    Size size = const Size(390, 844),
    double textScale = 1,
    bool settle = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final fake = fakeOffersService();
    final answer = list ?? offers;
    api = fake.api..onFetch = onFetch ?? () async => answer;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: OffersScreen(skills: skills, service: fake.service),
      ),
    );
    // Pas de pumpAndSettle pendant le chargement : l'indicateur tourne
    // sans fin.
    if (settle) await tester.pumpAndSettle();
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

  group('Chargement depuis le serveur', () {
    testWidgets(
      'Envoie les compétences, affiche le chargement puis les offres',
      (tester) async {
        final answer = Completer<List<Offer>>();
        await pumpScreen(tester, onFetch: () => answer.future, settle: false);
        await tester.pump();

        expect(find.text(OffersScreen.loadingText), findsOneWidget);
        expect(find.byType(OfferCard), findsNothing);
        expect(api.calls.single.skills, skills);
        expect(api.calls.single.token, fakeOffersToken);

        answer.complete(offers);
        await tester.pumpAndSettle();

        expect(find.text(OffersScreen.loadingText), findsNothing);
        expect(find.byType(OfferCard), findsNWidgets(offers.length));
      },
    );

    testWidgets('Erreur : message, puis « Réessayer » qui réussit', (
      tester,
    ) async {
      var attempt = 0;
      await pumpScreen(
        tester,
        onFetch: () async {
          attempt++;
          if (attempt == 1) throw const OffersException(OffersFailure.network);
          return offers;
        },
      );

      expect(find.text(OffersFailure.network.message), findsOneWidget);
      expect(find.byType(OfferCard), findsNothing);

      await tapVisible(tester, find.byKey(OffersScreen.retryButtonKey));
      await tester.pumpAndSettle();

      expect(api.calls, hasLength(2));
      expect(find.text(OffersFailure.network.message), findsNothing);
      expect(card('stage'), findsOneWidget);
    });

    testWidgets('Erreur imprévue : message générique, sans détail', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        onFetch: () async => throw StateError('détail technique secret'),
      );

      expect(find.text(OffersFailure.unknown.message), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
    });

    testWidgets('401 : jeton effacé, Connexion avec « Session expirée »', (
      tester,
    ) async {
      final fake = fakeOffersService();
      fake.api.onFetch = () async =>
          throw const OffersException(OffersFailure.sessionExpired);
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: OffersScreen(skills: skills, service: fake.service),
        ),
      );
      await tester.pumpAndSettle();

      expect(fake.store.token, isNull);
      expect(find.text(OffersScreen.heading), findsNothing);
      expect(find.text('Bon retour'), findsOneWidget); // titre Connexion
      expect(find.text(sessionExpiredMessage), findsOneWidget);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('Aucune offre : un message le dit', (tester) async {
      await pumpScreen(tester, list: const []);

      expect(find.text(OffersScreen.noOffers), findsOneWidget);
      expect(find.byType(OfferCard), findsNothing);
    });
  });

  group('Affichage des offres', () {
    testWidgets('Titre, bandeaux, une carte par offre', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Offres'), findsOneWidget); // barre du haut
      expect(find.text(OffersScreen.heading), findsOneWidget);
      expect(find.text(OffersScreen.scoreInfo), findsOneWidget);
      for (final o in offers) {
        expect(card(o.id), findsOneWidget, reason: o.id);
      }
    });

    testWidgets('Ordre du serveur respecté, score affiché tel quel', (
      tester,
    ) async {
      // Volontairement PAS du meilleur au plus faible : l'écran ne trie pas.
      await pumpScreen(tester, list: [offers[3], offers[0], offers[2]]);

      double top(String id) => tester.getTopLeft(card(id)).dy;
      expect(top('pfe'), lessThan(top('complet')));
      expect(top('complet'), lessThan(top('web')));

      for (final (id, score) in [('pfe', 30), ('complet', 100), ('web', 50)]) {
        expect(
          find.descendant(of: card(id), matching: find.text('$score %')),
          findsOneWidget,
          reason: id,
        );
      }
    });

    testWidgets('L\'explication du serveur est affichée sur la carte', (
      tester,
    ) async {
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

    testWidgets('Badge « Offre d\'exemple » seulement si isSample', (
      tester,
    ) async {
      await pumpScreen(tester);

      Finder badge(String id) => find.descendant(
        of: card(id),
        matching: find.text(OfferCard.sampleBadge),
      );
      expect(badge('stage'), findsOneWidget);
      expect(badge('complet'), findsNothing);
      expect(badge('web'), findsNothing);
      // Au moins un exemple : le bandeau ambre l'explique.
      expect(find.text(OffersScreen.sampleBanner), findsOneWidget);
    });

    testWidgets('Aucun exemple : ni badge ni bandeau ambre', (tester) async {
      await pumpScreen(tester, list: [offers[0], offers[2]]);

      expect(find.text(OfferCard.sampleBadge), findsNothing);
      expect(find.text(OffersScreen.sampleBanner), findsNothing);
    });

    testWidgets('Toucher une compétence manquante ouvre ses formations', (
      tester,
    ) async {
      await pumpScreen(tester);
      // Un filtre choisi avant : il doit être conservé au retour.
      await tapVisible(
        tester,
        find.byKey(OffersScreen.filterKey(OfferType.stage)),
      );

      await tapVisible(tester, chip('stage', 'Docker', SkillChipKind.missing));
      // pumpAndSettle attend la fin de l'animation de transition.
      await tester.pumpAndSettle();

      // Les formations d'exemple de Docker s'affichent.
      expect(find.text(TrainingsScreen.heading('Docker')), findsOneWidget);
      expect(find.byType(TrainingCard), findsWidgets);
      expect(find.text(OffersScreen.heading), findsNothing);

      // « Retour » revient aux offres, avec le même filtre et sans
      // nouvelle requête.
      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();
      expect(find.text(OffersScreen.heading), findsOneWidget);
      expect(card('stage'), findsOneWidget);
      expect(card('web'), findsNothing);
      expect(api.calls, hasLength(1));
    });
  });

  group('Filtres sur la liste reçue', () {
    testWidgets('Tout, Emplois, Stages, PFE', (tester) async {
      await pumpScreen(tester);

      await tapVisible(
        tester,
        find.byKey(OffersScreen.filterKey(OfferType.pfe)),
      );
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
      // Le filtre garde l'ordre du serveur.
      expect(
        tester.getTopLeft(card('complet')).dy,
        lessThan(tester.getTopLeft(card('web')).dy),
      );

      await tapVisible(tester, find.byKey(OffersScreen.filterKey(null)));
      for (final o in offers) {
        expect(card(o.id), findsOneWidget, reason: o.id);
      }
      // Filtrer ne redemande rien au serveur.
      expect(api.calls, hasLength(1));
    });

    testWidgets('Filtre sans offre : un message le dit', (tester) async {
      await pumpScreen(tester, list: [offers[1]]); // un seul stage

      await tapVisible(
        tester,
        find.byKey(OffersScreen.filterKey(OfferType.pfe)),
      );

      expect(find.text(OffersScreen.emptyFilter), findsOneWidget);
      expect(find.byType(OfferCard), findsNothing);
    });
  });

  group('Mise en page et contenu', () {
    testWidgets('Petit écran et texte agrandi : rien ne déborde', (
      tester,
    ) async {
      // Un débordement (« RenderFlex overflowed ») ferait échouer ce test.
      await pumpScreen(tester, size: const Size(320, 640), textScale: 2);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Erreur sur petit écran et texte agrandi', (tester) async {
      await pumpScreen(
        tester,
        onFetch: () async =>
            throw const OffersException(OffersFailure.tooManySkills),
        size: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(OffersFailure.tooManySkills.message), findsOneWidget);
    });

    testWidgets('Chargement sur petit écran et texte agrandi', (tester) async {
      await pumpScreen(
        tester,
        onFetch: () => Completer<List<Offer>>().future,
        size: const Size(320, 640),
        textScale: 2,
        settle: false,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(OffersScreen.loadingText), findsOneWidget);
    });

    testWidgets('Offres respecte les règles de contenu', (tester) async {
      await pumpScreen(tester);

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
      for (final removed in [
        'Source',
        'TND',
        'Détails',
        'Match',
        'maximiser',
      ]) {
        expect(find.textContaining(removed), findsNothing, reason: removed);
      }
      // Le score reste présenté comme une aide.
      expect(find.textContaining('pas une garantie'), findsOneWidget);
    });
  });
}
