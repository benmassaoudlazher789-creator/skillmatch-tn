import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/core/theme/widgets/skill_chip.dart';
import 'package:skillmatch_tn/features/trainings/data/sample_trainings.dart';
import 'package:skillmatch_tn/features/trainings/domain/training.dart';
import 'package:skillmatch_tn/features/trainings/presentation/trainings_screen.dart';
import 'package:skillmatch_tn/features/trainings/presentation/widgets/training_card.dart';

void main() {
  // Catalogue fictif, propre aux tests : ils ne dépendent pas des
  // formations d'exemple de l'application.
  const catalog = [
    Training(
      id: 'docker-projet',
      skill: 'Docker',
      title: 'Projet conteneurs test',
      level: TrainingLevel.intermediaire,
      hours: 6,
      type: TrainingType.projetPratique,
    ),
    Training(
      id: 'docker-cours',
      skill: 'Docker',
      title: 'Cours conteneurs test',
      level: TrainingLevel.debutant,
      hours: 3,
      type: TrainingType.coursEnLigne,
    ),
    Training(
      id: 'react-tuto',
      skill: 'React',
      title: 'Tutoriel React test',
      level: TrainingLevel.debutant,
      hours: 2,
      type: TrainingType.tutoriel,
    ),
  ];

  /// Ouvre l'écran Formations par-dessus un écran d'accueil, comme depuis
  /// l'écran Offres : on peut ainsi tester le retour.
  Future<void> pumpScreen(
    WidgetTester tester, {
    required String skill,
    List<Training> trainings = catalog,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
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
                        TrainingsScreen(skill: skill, trainings: trainings),
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
    await tester.pumpAndSettle();
  }

  Finder card(String id) => find.byKey(TrainingsScreen.cardKey(id));

  testWidgets('Affichage des formations d\'une compétence', (tester) async {
    await pumpScreen(tester, skill: 'Docker');

    expect(find.text('Formations'), findsOneWidget); // barre du haut
    expect(find.text(TrainingsScreen.heading('Docker')), findsOneWidget);
    expect(find.text(TrainingsScreen.subtitle), findsOneWidget);
    expect(find.text(TrainingsScreen.disclaimer), findsOneWidget);
    expect(find.text(TrainingsScreen.countLabel(2)), findsOneWidget);

    // La compétence est rappelée en rouge.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is SkillChip &&
            w.label == 'Docker' &&
            w.kind == SkillChipKind.missing,
      ),
      findsOneWidget,
    );

    // Seules les formations Docker, chacune avec ses informations.
    expect(find.byType(TrainingCard), findsNWidgets(2));
    expect(card('react-tuto'), findsNothing);
    // textContaining : durée, niveau et type sont des Text.rich dont
    // l'icône (WidgetSpan) compte comme un caractère invisible ; le texte
    // exact ne serait donc pas « environ 3 h ».
    final cours = card('docker-cours');
    expect(
      find.descendant(of: cours, matching: find.text('Cours conteneurs test')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: cours, matching: find.text(TrainingCard.sampleBadge)),
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

  testWidgets('Tri : Débutant avant Intermédiaire', (tester) async {
    await pumpScreen(tester, skill: 'Docker');

    expect(
      tester.getTopLeft(card('docker-cours')).dy,
      lessThan(tester.getTopLeft(card('docker-projet')).dy),
    );
  });

  testWidgets('Majuscules ignorées : « docker » trouve « Docker »', (
    tester,
  ) async {
    await pumpScreen(tester, skill: 'docker');

    expect(find.byType(TrainingCard), findsNWidgets(2));
  });

  testWidgets('Compétence sans formation : message et retour aux offres', (
    tester,
  ) async {
    await pumpScreen(tester, skill: 'Windows');

    expect(find.text(TrainingsScreen.heading('Windows')), findsOneWidget);
    expect(find.text(TrainingsScreen.emptyMessage('Windows')), findsOneWidget);
    expect(find.byType(TrainingCard), findsNothing);
    expect(find.textContaining("formation d'exemple"), findsWidgets);
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
    await pumpScreen(tester, skill: 'Docker');

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    expect(find.text('Accueil test'), findsOneWidget);
  });

  testWidgets('Formations d\'exemple : chaque carte porte le badge', (
    tester,
  ) async {
    await pumpScreen(tester, skill: 'Docker', trainings: sampleTrainings);

    final count = tester.widgetList(find.byType(TrainingCard)).length;
    expect(count, greaterThan(0));
    expect(find.text(TrainingCard.sampleBadge), findsNWidgets(count));
  });

  for (final skill in ['Docker', 'Windows']) {
    testWidgets('Petit écran et texte agrandi ($skill) : rien ne déborde', (
      tester,
    ) async {
      // Un débordement (« RenderFlex overflowed ») ferait échouer ce test.
      await pumpScreen(
        tester,
        skill: skill,
        trainings: sampleTrainings,
        size: const Size(320, 640),
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      expect(find.text(TrainingsScreen.heading(skill)), findsOneWidget);
    });
  }

  testWidgets('Formations respecte les règles de contenu', (tester) async {
    await pumpScreen(tester, skill: 'Docker', trainings: sampleTrainings);

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
      'Payant',
      'Gratuit',
      'Voir la formation',
      'Présentiel',
    ]) {
      expect(find.textContaining(removed), findsNothing, reason: removed);
    }
  });
}
