import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/core/theme/widgets/skill_chip.dart';
import 'package:skillmatch_tn/features/auth/domain/auth_failure.dart';
import 'package:skillmatch_tn/features/cv/domain/cv_failure.dart';
import 'package:skillmatch_tn/features/offers/presentation/offers_screen.dart';
import 'package:skillmatch_tn/features/skills/domain/skill_rules.dart';
import 'package:skillmatch_tn/features/skills/presentation/skills_review_screen.dart';

import 'support/fake_cv.dart';
import 'support/fake_offers.dart';

void main() {
  // Liste fictive, propre aux tests.
  const skills = ['Dart', 'Flutter', 'SQL', 'Git'];

  late FakeCvApi api;
  late FakeOffersApi offersApi;

  // Même principe que les autres tests : MaterialApp sans AppTheme, car
  // google_fonts n'a pas Internet pendant les tests.
  // [onAnalyze] remplace la réponse du serveur : aucun appel réseau réel.
  // Par défaut, le serveur renvoie [initial] et l'écran affiche le résultat.
  Future<void> pumpScreen(
    WidgetTester tester, {
    List<String> initial = skills,
    Future<List<String>> Function()? onAnalyze,
    Size size = const Size(390, 844),
    double textScale = 1,
    bool settle = true,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final fake = fakeCvService();
    api = fake.api..onAnalyze = onAnalyze ?? () async => initial;
    // Faux service d'offres, transmis à l'écran Offres : aucun réseau. Il
    // renvoie une offre où Flutter est acquis, comme le ferait le serveur.
    final offersFake = fakeOffersService();
    offersApi = offersFake.api
      ..onFetch = () async => [
        fakeOffer(
          id: 'mobile',
          score: 70,
          requiredAcquired: ['Flutter', 'Dart'],
          preferredMissing: ['Git'],
        ),
      ];
    await tester.pumpWidget(
      MaterialApp(
        // Permet de simuler un texte agrandi dans les réglages du téléphone.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: SkillsReviewScreen(
          file: fakeCvFile,
          service: fake.service,
          offersService: offersFake.service,
        ),
      ),
    );
    // pumpAndSettle attend la réponse (immédiate) du faux serveur. Pas
    // pendant le chargement : l'indicateur tourne sans fin, pumpAndSettle
    // ne s'arrêterait jamais.
    if (settle) await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  /// Saisit [value] dans le champ, puis touche « Ajouter ».
  Future<void> addSkill(WidgetTester tester, String value) async {
    final field = find.byKey(SkillsReviewScreen.skillFieldKey);
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await tapVisible(tester, find.byKey(SkillsReviewScreen.addButtonKey));
  }

  bool offersEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.byKey(SkillsReviewScreen.offersButtonKey))
          .onPressed !=
      null;

  group('Analyse du CV', () {
    testWidgets('« Analyse en cours… » puis le résultat réel', (tester) async {
      final answer = Completer<List<String>>();
      await pumpScreen(tester, onAnalyze: () => answer.future, settle: false);
      await tester.pump();

      expect(find.text(SkillsReviewScreen.loadingText), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Pendant l'analyse : pas encore de liste ni de bouton « Voir les
      // offres », mais « Importer un autre CV » reste possible.
      expect(find.byKey(SkillsReviewScreen.offersButtonKey), findsNothing);
      expect(find.text('Importer un autre CV'), findsOneWidget);
      expect(api.calls, hasLength(1));

      answer.complete(['Python', 'Docker']);
      await tester.pumpAndSettle();

      expect(find.text(SkillsReviewScreen.loadingText), findsNothing);
      expect(find.byTooltip('Retirer Python'), findsOneWidget);
      expect(find.byTooltip('Retirer Docker'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(offersEnabled(tester), isTrue);
    });

    testWidgets('Le bandeau « exemple » a disparu', (tester) async {
      await pumpScreen(tester);

      expect(find.textContaining('Exemple de résultat'), findsNothing);
      expect(find.textContaining('prochaine version'), findsNothing);
    });

    testWidgets('Erreur : message, puis « Réessayer » qui réussit', (
      tester,
    ) async {
      var attempt = 0;
      await pumpScreen(
        tester,
        onAnalyze: () async {
          attempt++;
          if (attempt == 1) throw const CvException(CvFailure.noText);
          return const ['Excel'];
        },
      );

      expect(find.text(CvFailure.noText.message), findsOneWidget);
      expect(find.byKey(SkillsReviewScreen.offersButtonKey), findsNothing);
      expect(find.text('Importer un autre CV'), findsOneWidget);

      await tapVisible(tester, find.byKey(SkillsReviewScreen.retryButtonKey));
      await tester.pumpAndSettle();

      expect(api.calls, hasLength(2));
      expect(find.text(CvFailure.noText.message), findsNothing);
      expect(find.byTooltip('Retirer Excel'), findsOneWidget);
    });

    testWidgets('Pendant un nouvel essai, « Analyse en cours… » revient', (
      tester,
    ) async {
      final second = Completer<List<String>>();
      var attempt = 0;
      await pumpScreen(
        tester,
        onAnalyze: () {
          attempt++;
          if (attempt == 1) {
            return Future.error(const CvException(CvFailure.network));
          }
          return second.future;
        },
      );
      expect(find.text(CvFailure.network.message), findsOneWidget);

      await tapVisible(tester, find.byKey(SkillsReviewScreen.retryButtonKey));

      expect(find.text(SkillsReviewScreen.loadingText), findsOneWidget);
      expect(find.text(CvFailure.network.message), findsNothing);

      second.complete(const ['Git']);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Retirer Git'), findsOneWidget);
    });

    testWidgets('Erreur imprévue : message générique, sans détail', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        onAnalyze: () async => throw StateError('détail technique secret'),
      );

      expect(find.text(CvFailure.unknown.message), findsOneWidget);
      expect(find.textContaining('secret'), findsNothing);
    });

    testWidgets('Aucune compétence reconnue : explication, bouton inactif', (
      tester,
    ) async {
      await pumpScreen(tester, initial: const []);

      expect(find.text(SkillsReviewScreen.noSkillFoundHint), findsOneWidget);
      expect(find.text(SkillsReviewScreen.atLeastOneHint), findsOneWidget);
      expect(offersEnabled(tester), isFalse);

      await addSkill(tester, 'Excel');
      expect(offersEnabled(tester), isTrue);
    });

    testWidgets(
      '401 : jeton effacé, retour à la Connexion avec « Session expirée »',
      (tester) async {
        final fake = fakeCvService();
        fake.api.onAnalyze = () async =>
            throw const CvException(CvFailure.sessionExpired);
        tester.view.physicalSize = const Size(390, 844) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: SkillsReviewScreen(file: fakeCvFile, service: fake.service),
          ),
        );
        await tester.pumpAndSettle();

        expect(fake.store.token, isNull);
        expect(find.text('Vos compétences'), findsNothing);
        expect(find.text('Bon retour'), findsOneWidget); // titre Connexion
        expect(find.text(sessionExpiredMessage), findsOneWidget);
        // Tous les écrans précédents ont été retirés : rien en dessous.
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        expect(navigator.canPop(), isFalse);
      },
    );
  });

  group('Relecture de la liste', () {
    testWidgets('Affichage : titre, puces, compteur', (tester) async {
      await pumpScreen(tester);

      expect(find.text('Compétences'), findsOneWidget); // barre du haut
      expect(find.text('Vos compétences'), findsOneWidget);
      expect(find.text('Compétences déclarées'), findsOneWidget);
      for (final skill in skills) {
        expect(find.text(skill), findsOneWidget, reason: skill);
        expect(find.byTooltip('Retirer $skill'), findsOneWidget, reason: skill);
      }
      expect(find.text('4'), findsOneWidget);
      expect(offersEnabled(tester), isTrue);
      expect(find.text(SkillsReviewScreen.atLeastOneHint), findsNothing);
    });

    testWidgets('Retrait d\'une compétence', (tester) async {
      await pumpScreen(tester);

      await tapVisible(tester, find.byTooltip('Retirer SQL'));

      expect(find.text('SQL'), findsNothing);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets(
      'Ajout : la saisie nettoyée devient une puce, le champ se vide',
      (tester) async {
        await pumpScreen(tester);

        await addSkill(tester, '  Docker  ');

        // Une seule fois : dans la puce, plus dans le champ (vidé).
        expect(find.text('Docker'), findsOneWidget);
        expect(find.byTooltip('Retirer Docker'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
      },
    );

    testWidgets('Ajout avec la touche OK du clavier', (tester) async {
      await pumpScreen(tester);

      final field = find.byKey(SkillsReviewScreen.skillFieldKey);
      await tester.ensureVisible(field);
      await tester.enterText(field, 'Figma');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(find.byTooltip('Retirer Figma'), findsOneWidget);
    });

    testWidgets('Doublon refusé, sans tenir compte des majuscules', (
      tester,
    ) async {
      await pumpScreen(tester);

      await addSkill(tester, 'flutter');

      expect(find.text(SkillRules.duplicateError), findsOneWidget);
      expect(find.byTooltip('Retirer flutter'), findsNothing);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('Champ vide refusé', (tester) async {
      await pumpScreen(tester);

      await addSkill(tester, '   ');

      expect(find.text(SkillRules.emptyError), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('La saisie est bloquée à 40 caractères', (tester) async {
      await pumpScreen(tester);

      await addSkill(tester, 'x' * 50);

      // Le champ coupe à 40 : la puce ajoutée fait exactement 40 caractères.
      expect(find.text('x' * SkillRules.maxLength), findsOneWidget);
      expect(find.text('x' * 50), findsNothing);
    });

    testWidgets('Une erreur disparaît après un ajout réussi', (tester) async {
      await pumpScreen(tester);

      await addSkill(tester, '');
      expect(find.text(SkillRules.emptyError), findsOneWidget);

      await addSkill(tester, 'Excel');
      expect(find.text(SkillRules.emptyError), findsNothing);
      expect(find.byTooltip('Retirer Excel'), findsOneWidget);
    });

    testWidgets('Sans compétence, « Voir les offres » est désactivé', (
      tester,
    ) async {
      await pumpScreen(tester, initial: const ['Git']);
      expect(offersEnabled(tester), isTrue);

      await tapVisible(tester, find.byTooltip('Retirer Git'));

      expect(offersEnabled(tester), isFalse);
      expect(find.text(SkillsReviewScreen.atLeastOneHint), findsOneWidget);
      // Liste vidée à la main : pas le message « aucune reconnue ».
      expect(find.text(SkillsReviewScreen.noSkillFoundHint), findsNothing);
      expect(find.text('0'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(SkillsReviewScreen.offersButtonKey),
      );
      await tester.tap(
        find.byKey(SkillsReviewScreen.offersButtonKey),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      // L'écran Offres ne s'ouvre pas.
      expect(find.text(OffersScreen.heading), findsNothing);

      // Une nouvelle compétence réactive le bouton.
      await addSkill(tester, 'Git');
      expect(offersEnabled(tester), isTrue);
    });

    testWidgets(
      '« Voir les offres » ouvre l\'écran Offres avec les compétences courantes',
      (tester) async {
        // On part d'une liste sans Flutter, puis on l'ajoute à la main.
        await pumpScreen(tester, initial: const ['Dart']);
        await addSkill(tester, 'Flutter');

        await tapVisible(
          tester,
          find.byKey(SkillsReviewScreen.offersButtonKey),
        );
        // pumpAndSettle attend la fin de l'animation de transition.
        await tester.pumpAndSettle();

        expect(find.text(OffersScreen.heading), findsOneWidget);
        // Les compétences COURANTES sont envoyées au serveur, Flutter
        // (ajouté à la main) compris.
        expect(offersApi.calls.single.skills, ['Dart', 'Flutter']);
        // Flutter apparaît en vert sur l'offre renvoyée, et jamais en rouge.
        bool isFlutter(Widget w, SkillChipKind kind) =>
            w is SkillChip && w.label == 'Flutter' && w.kind == kind;
        expect(
          find.byWidgetPredicate((w) => isFlutter(w, SkillChipKind.acquired)),
          findsWidgets,
        );
        expect(
          find.byWidgetPredicate((w) => isFlutter(w, SkillChipKind.missing)),
          findsNothing,
        );

        // « Retour » revient à Vos compétences, avec la liste intacte.
        await tester.tap(find.byTooltip('Retour'));
        await tester.pumpAndSettle();
        expect(find.text(OffersScreen.heading), findsNothing);
        expect(find.byTooltip('Retirer Flutter'), findsOneWidget);
        expect(find.byTooltip('Retirer Dart'), findsOneWidget);
        // Revenir ici ne relance pas l'analyse.
        expect(api.calls, hasLength(1));
      },
    );
  });

  group('Mise en page et contenu', () {
    testWidgets('Petit écran et texte agrandi : rien ne déborde', (
      tester,
    ) async {
      // Un débordement (« RenderFlex overflowed ») ferait échouer ce test.
      await pumpScreen(
        tester,
        initial: ['Dart', 'G' * SkillRules.maxLength],
        size: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('G' * SkillRules.maxLength), findsOneWidget);
    });

    testWidgets('Erreur sur petit écran et texte agrandi : rien ne déborde', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        onAnalyze: () async =>
            throw const CvException(CvFailure.passwordProtected),
        size: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(CvFailure.passwordProtected.message), findsOneWidget);
    });

    testWidgets('Chargement sur petit écran et texte agrandi', (tester) async {
      await pumpScreen(
        tester,
        onAnalyze: () => Completer<List<String>>().future,
        size: const Size(320, 640),
        textScale: 2,
        settle: false,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(SkillsReviewScreen.loadingText), findsOneWidget);
    });

    testWidgets('Vos compétences respecte les règles de contenu', (
      tester,
    ) async {
      await pumpScreen(tester);
      await addSkill(tester, '');

      // Mots interdits par CLAUDE.md, et promesses qu'on ne peut pas tenir.
      for (final word in [
        'vérifié',
        'Vérifi',
        'certifié',
        'prouvé',
        'passeport',
        'défi',
        'chiffré',
        'robot',
      ]) {
        expect(find.textContaining(word), findsNothing, reason: word);
      }
      // Éléments de la maquette volontairement retirés.
      for (final removed in [
        'Dernière étape',
        'Match élevé',
        'Analysé avec succès',
        'recruteurs',
        'Suggestions',
      ]) {
        expect(find.textContaining(removed), findsNothing, reason: removed);
      }
      // Le score reste présenté comme une aide.
      expect(find.textContaining('pas une garantie'), findsOneWidget);
    });
  });
}
