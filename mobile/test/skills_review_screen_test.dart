import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/core/theme/widgets/skill_chip.dart';
import 'package:skillmatch_tn/features/offers/presentation/offers_screen.dart';
import 'package:skillmatch_tn/features/skills/domain/skill_rules.dart';
import 'package:skillmatch_tn/features/skills/presentation/skills_review_screen.dart';

void main() {
  // Liste fictive, propre aux tests.
  const skills = ['Dart', 'Flutter', 'SQL', 'Git'];

  // Même principe que les autres tests : MaterialApp sans AppTheme, car
  // google_fonts n'a pas Internet pendant les tests.
  Future<void> pumpScreen(
    WidgetTester tester, {
    List<String> initial = skills,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        // Permet de simuler un texte agrandi dans les réglages du téléphone.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: SkillsReviewScreen(initialSkills: initial),
      ),
    );
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

  testWidgets('Affichage : titre, bandeau d\'exemple, puces, compteur', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Compétences'), findsOneWidget); // barre du haut
    expect(find.text('Vos compétences'), findsOneWidget);
    expect(find.text(SkillsReviewScreen.exampleBanner), findsOneWidget);
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

  testWidgets('Ajout : la saisie nettoyée devient une puce, le champ se vide', (
    tester,
  ) async {
    await pumpScreen(tester);

    await addSkill(tester, '  Docker  ');

    // Une seule fois : dans la puce, plus dans le champ (vidé).
    expect(find.text('Docker'), findsOneWidget);
    expect(find.byTooltip('Retirer Docker'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

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
    expect(find.text('0'), findsOneWidget);

    await tester.ensureVisible(find.byKey(SkillsReviewScreen.offersButtonKey));
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

      await tapVisible(tester, find.byKey(SkillsReviewScreen.offersButtonKey));
      // pumpAndSettle attend la fin de l'animation de transition.
      await tester.pumpAndSettle();

      expect(find.text(OffersScreen.heading), findsOneWidget);
      // Flutter, ajouté juste avant, apparaît en vert sur les offres
      // d'exemple qui le demandent, et jamais en rouge.
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
    },
  );

  testWidgets('Petit écran et texte agrandi : rien ne déborde', (tester) async {
    // Un débordement (« RenderFlex overflowed ») ferait échouer ce test.
    await pumpScreen(
      tester,
      initial: ['Dart', 'G' * SkillRules.maxLength],
      size: const Size(320, 640),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('G' * SkillRules.maxLength), findsOneWidget);
  });

  testWidgets('Vos compétences respecte les règles de contenu', (tester) async {
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
      'détecté',
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
  });
}
