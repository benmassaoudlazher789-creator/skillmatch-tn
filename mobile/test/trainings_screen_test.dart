import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/core/theme/widgets/skill_chip.dart';
import 'package:skillmatch_tn/features/auth/domain/auth_failure.dart';
import 'package:skillmatch_tn/features/trainings/domain/training.dart';
import 'package:skillmatch_tn/features/trainings/domain/trainings_failure.dart';
import 'package:skillmatch_tn/features/trainings/presentation/trainings_screen.dart';
import 'package:skillmatch_tn/features/trainings/presentation/widgets/training_card.dart';

import 'support/fake_trainings.dart';

void main() {
  // Formations fictives, propres aux tests, dans l'ordre qu'aurait choisi le
  // serveur. L'écran ne trie et ne filtre rien.
  final trainings = [
    fakeTraining(
      id: 'docker-cours',
      title: 'Cours conteneurs test',
      level: TrainingLevel.debutant,
      hours: 3,
      type: TrainingType.coursEnLigne,
      isSample: true,
    ),
    fakeTraining(
      id: 'docker-projet',
      title: 'Projet conteneurs test',
      level: TrainingLevel.intermediaire,
      hours: 6,
      type: TrainingType.projetPratique,
      // Un lien rempli : la carte ne doit quand même afficher aucun bouton.
      url: 'https://example.com/formation-test',
    ),
  ];

  late FakeTrainingsApi api;

  /// Ouvre l'écran Formations par-dessus un écran d'accueil, comme depuis
  /// l'écran Offres : on peut ainsi tester le retour.
  /// [onFetch] remplace la réponse du serveur : aucun appel réseau réel.
  Future<void> pumpScreen(
    WidgetTester tester, {
    String skill = 'Docker',
    List<Training>? list,
    Future<List<Training>> Function()? onFetch,
    String? token = fakeTrainingsToken,
    Size size = const Size(390, 844),
    double textScale = 1,
    bool settle = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final fake = fakeTrainingsService(token: token);
    final answer = list ?? trainings;
    api = fake.api..onFetch = onFetch ?? () async => answer;
    // Même principe que les autres tests : MaterialApp sans AppTheme, car
    // google_fonts n'a pas Internet pendant les tests.
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        TrainingsScreen(skill: skill, service: fake.service),
                  ),
                ),
                child: const Text('Accueil test'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Accueil test'));
    // Pas de pumpAndSettle pendant le chargement : l'indicateur tourne
    // sans fin. Deux pump suffisent à afficher l'écran poussé.
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Finder card(String id) => find.byKey(TrainingsScreen.cardKey(id));

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  group('Chargement depuis le serveur', () {
    testWidgets(
      'Envoie la compétence, affiche le chargement puis les formations',
      (tester) async {
        final answer = Completer<List<Training>>();
        await pumpScreen(
          tester,
          skill: 'Power BI',
          onFetch: () => answer.future,
          settle: false,
        );

        expect(find.text(TrainingsScreen.loadingText), findsOneWidget);
        expect(find.byType(TrainingCard), findsNothing);
        expect(api.calls.single.skill, 'Power BI');
        expect(api.calls.single.token, fakeTrainingsToken);

        answer.complete(trainings);
        await tester.pumpAndSettle();

        expect(find.text(TrainingsScreen.loadingText), findsNothing);
        expect(find.byType(TrainingCard), findsNWidgets(trainings.length));
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
          if (attempt == 1) {
            throw const TrainingsException(TrainingsFailure.network);
          }
          return trainings;
        },
      );

      expect(find.text(TrainingsFailure.network.message), findsOneWidget);
      expect(find.byType(TrainingCard), findsNothing);

      await tapVisible(tester, find.byKey(TrainingsScreen.retryButtonKey));
      await tester.pumpAndSettle();

      expect(api.calls, hasLength(2));
      expect(find.text(TrainingsFailure.network.message), findsNothing);
      expect(card('docker-cours'), findsOneWidget);
    });

    testWidgets('Double appui sur « Réessayer » : une seule requête', (
      tester,
    ) async {
      var attempt = 0;
      final second = Completer<List<Training>>();
      await pumpScreen(
        tester,
        onFetch: () {
          attempt++;
          if (attempt == 1) {
            return Future.error(
              const TrainingsException(TrainingsFailure.network),
            );
          }
          return second.future;
        },
      );

      final retry = find.byKey(TrainingsScreen.retryButtonKey);
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      // Second appui avant toute reconstruction : le bouton est encore là.
      await tester.tap(retry, warnIfMissed: false);
      await tester.pump();

      expect(api.calls, hasLength(2));
      second.complete(trainings);
      await tester.pumpAndSettle();
      expect(api.calls, hasLength(2));
    });

    testWidgets('Erreur imprévue : message générique, sans détail', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        onFetch: () async => throw StateError('détail technique secret'),
      );

      expect(find.text(TrainingsFailure.unknown.message), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
    });

    testWidgets('401 : jeton effacé, Connexion avec « Session expirée »', (
      tester,
    ) async {
      final fake = fakeTrainingsService();
      fake.api.onFetch = () async =>
          throw const TrainingsException(TrainingsFailure.sessionExpired);
      tester.view.physicalSize = const Size(390, 844) * 3;
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: TrainingsScreen(skill: 'Docker', service: fake.service),
        ),
      );
      await tester.pumpAndSettle();

      expect(fake.store.token, isNull);
      expect(find.text(TrainingsScreen.heading('Docker')), findsNothing);
      expect(find.text('Bon retour'), findsOneWidget); // titre Connexion
      expect(find.text(sessionExpiredMessage), findsOneWidget);
      expect(sessionExpiredMessage, 'Session expirée, reconnectez-vous.');
      // On ne peut pas revenir en arrière vers un écran sans session.
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('Sans jeton : Connexion, aucune requête', (tester) async {
      await pumpScreen(tester, token: null);

      expect(api.calls, isEmpty);
      expect(find.text(sessionExpiredMessage), findsOneWidget);
    });
  });

  group('Affichage des formations', () {
    testWidgets('Titre, compétence en rouge, compteur, cartes', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Formations'), findsOneWidget); // barre du haut
      expect(find.text(TrainingsScreen.heading('Docker')), findsOneWidget);
      expect(find.text(TrainingsScreen.subtitle), findsOneWidget);
      expect(find.text(TrainingsScreen.disclaimer), findsOneWidget);
      expect(find.text(TrainingsScreen.countLabel(2)), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is SkillChip &&
              w.label == 'Docker' &&
              w.kind == SkillChipKind.missing,
        ),
        findsOneWidget,
      );

      // textContaining : durée, niveau et type sont des Text.rich dont
      // l'icône (WidgetSpan) compte comme un caractère invisible.
      final cours = card('docker-cours');
      expect(
        find.descendant(
          of: cours,
          matching: find.text('Cours conteneurs test'),
        ),
        findsOneWidget,
      );
      for (final value in ['environ 3 h', 'Débutant', 'Cours en ligne']) {
        expect(
          find.descendant(of: cours, matching: find.textContaining(value)),
          findsOneWidget,
          reason: value,
        );
      }
      final projet = card('docker-projet');
      for (final value in ['environ 6 h', 'Intermédiaire', 'Projet pratique']) {
        expect(
          find.descendant(of: projet, matching: find.textContaining(value)),
          findsOneWidget,
          reason: value,
        );
      }
    });

    testWidgets('Ordre du serveur respecté, sans retri', (tester) async {
      // Volontairement Intermédiaire avant Débutant : l'écran ne trie pas.
      await pumpScreen(tester, list: [trainings[1], trainings[0]]);

      expect(
        tester.getTopLeft(card('docker-projet')).dy,
        lessThan(tester.getTopLeft(card('docker-cours')).dy),
      );
    });

    testWidgets('Badge « Formation d\'exemple » seulement si isSample', (
      tester,
    ) async {
      await pumpScreen(tester);

      Finder badge(String id) => find.descendant(
        of: card(id),
        matching: find.text(TrainingCard.sampleBadge),
      );
      expect(badge('docker-cours'), findsOneWidget);
      expect(badge('docker-projet'), findsNothing);
      // Au moins un exemple : le bandeau ambre l'explique.
      expect(find.text(TrainingsScreen.sampleBanner), findsOneWidget);
    });

    testWidgets('Aucun exemple : ni badge ni bandeau ambre', (tester) async {
      await pumpScreen(tester, list: [trainings[1]]);

      expect(find.text(TrainingCard.sampleBadge), findsNothing);
      expect(find.text(TrainingsScreen.sampleBanner), findsNothing);
      // Le rappel « pas une garantie » reste affiché.
      expect(find.text(TrainingsScreen.disclaimer), findsOneWidget);
    });

    testWidgets('Aucun bouton de lien, même avec un lien rempli', (
      tester,
    ) async {
      await pumpScreen(tester);

      final projet = card('docker-projet');
      for (final type in [
        FilledButton,
        OutlinedButton,
        TextButton,
        IconButton,
      ]) {
        expect(
          find.descendant(of: projet, matching: find.byType(type)),
          findsNothing,
          reason: '$type',
        );
      }
      expect(find.textContaining('example.com'), findsNothing);
      expect(find.textContaining('Ouvrir'), findsNothing);
    });

    testWidgets('Compétence sans formation : message et retour aux offres', (
      tester,
    ) async {
      await pumpScreen(tester, skill: 'Windows', list: const []);

      expect(find.text(TrainingsScreen.heading('Windows')), findsOneWidget);
      expect(
        find.text(TrainingsScreen.emptyMessage('Windows')),
        findsOneWidget,
      );
      expect(find.byType(TrainingCard), findsNothing);
      // Pas de compteur « 0 formation ».
      expect(find.text(TrainingsScreen.countLabel(0)), findsNothing);

      await tester.ensureVisible(find.text(TrainingsScreen.backToOffers));
      await tester.tap(find.text(TrainingsScreen.backToOffers));
      await tester.pumpAndSettle();

      expect(find.text('Accueil test'), findsOneWidget);
      expect(find.text(TrainingsScreen.heading('Windows')), findsNothing);
    });

    testWidgets('Le bouton Retour de la barre revient à l\'écran précédent', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byTooltip('Retour'));
      await tester.pumpAndSettle();

      expect(find.text('Accueil test'), findsOneWidget);
    });
  });

  group('Mise en page et contenu', () {
    // Un débordement (« RenderFlex overflowed ») ferait échouer ces tests.
    const small = Size(320, 640);

    testWidgets('Liste sur petit écran et texte agrandi', (tester) async {
      await pumpScreen(tester, size: small, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(find.text(TrainingsScreen.heading('Docker')), findsOneWidget);
    });

    testWidgets('Liste vide sur petit écran et texte agrandi', (tester) async {
      await pumpScreen(
        tester,
        skill: 'Windows',
        list: const [],
        size: small,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(
        find.text(TrainingsScreen.emptyMessage('Windows')),
        findsOneWidget,
      );
    });

    testWidgets('Erreur sur petit écran et texte agrandi', (tester) async {
      await pumpScreen(
        tester,
        onFetch: () async =>
            throw const TrainingsException(TrainingsFailure.skillTooLong),
        size: small,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(TrainingsFailure.skillTooLong.message), findsOneWidget);
    });

    testWidgets('Chargement sur petit écran et texte agrandi', (tester) async {
      await pumpScreen(
        tester,
        onFetch: () => Completer<List<Training>>().future,
        size: small,
        textScale: 2,
        settle: false,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(TrainingsScreen.loadingText), findsOneWidget);
    });

    testWidgets('Formations respecte les règles de contenu', (tester) async {
      await pumpScreen(tester);

      // Mots interdits par CLAUDE.md (racines, pour couvrir les accords).
      for (final word in [
        'vérifi',
        'Vérifi',
        'certifi',
        'Certifi',
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
        'LinkedIn',
        'Tanitjobs',
        'Keejob',
        'Payant',
        'Gratuit',
        'Voir la formation',
        'Présentiel',
      ]) {
        expect(find.textContaining(removed), findsNothing, reason: removed);
      }
    });
  });
}
