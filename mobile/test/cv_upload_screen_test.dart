import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/cv/data/cv_picker.dart';
import 'package:skillmatch_tn/features/cv/domain/cv_file_rules.dart';
import 'package:skillmatch_tn/features/cv/presentation/cv_upload_screen.dart';

/// Faux sélecteur : renvoie le fichier qu'on lui a donné, sans ouvrir de
/// vraie fenêtre système. null = l'utilisateur a annulé.
class FakeCvPicker implements CvPicker {
  PickedCvFile? next;
  bool shouldFail = false;
  int calls = 0;

  @override
  Future<PickedCvFile?> pick() async {
    calls++;
    if (shouldFail) throw Exception('sélecteur indisponible');
    return next;
  }
}

void main() {
  const mega = 1024 * 1024;

  // Fichiers fictifs, propres aux tests.
  final validPdf = PickedCvFile(
    name: 'cv_candidat.pdf',
    sizeInBytes: (1.2 * mega).round(),
  );
  const validDocx = PickedCvFile(name: 'cv_v2.docx', sizeInBytes: 350 * 1024);
  const imageFile = PickedCvFile(name: 'photo.png', sizeInBytes: 1000);
  const hugeFile = PickedCvFile(name: 'cv_lourd.pdf', sizeInBytes: 6 * mega);

  // Grand titre de l'écran Vos compétences : sert à savoir s'il est ouvert.
  const skillsHeading = 'Vos compétences';

  late FakeCvPicker picker;

  // Même principe que les autres tests : MaterialApp sans AppTheme, car
  // google_fonts n'a pas Internet pendant les tests.
  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    picker = FakeCvPicker();
    await tester.pumpWidget(MaterialApp(home: CvUploadScreen(picker: picker)));
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> choose(WidgetTester tester, PickedCvFile? file) async {
    picker.next = file;
    await tapVisible(tester, find.byKey(CvUploadScreen.pickButtonKey));
  }

  bool analyzeEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.byKey(CvUploadScreen.analyzeButtonKey))
          .onPressed !=
      null;

  testWidgets('État initial : consignes, aucun fichier, aucune erreur', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Ajout du CV'), findsOneWidget);
    expect(find.text('Ajoutez votre CV'), findsOneWidget);
    expect(find.text('Choisissez votre CV'), findsOneWidget);
    expect(find.text(CvFileRules.formatsHint), findsOneWidget);
    expect(find.text('Choisir un fichier'), findsOneWidget);
    expect(find.text('Analyser mon CV'), findsOneWidget);
    expect(
      find.textContaining('Votre CV reste sur votre téléphone'),
      findsOneWidget,
    );
    expect(find.byTooltip('Retirer le fichier'), findsNothing);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  testWidgets('Sans fichier, le bouton d\'analyse est désactivé', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(analyzeEnabled(tester), isFalse);
    await tester.ensureVisible(find.byKey(CvUploadScreen.analyzeButtonKey));
    await tester.tap(
      find.byKey(CvUploadScreen.analyzeButtonKey),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    // L'écran Vos compétences ne s'ouvre pas.
    expect(find.text(skillsHeading), findsNothing);
    expect(find.text('Ajoutez votre CV'), findsOneWidget);
  });

  testWidgets('Fichier valide : nom, taille, bouton actif', (tester) async {
    await pumpScreen(tester);
    await choose(tester, validPdf);

    expect(find.text('cv_candidat.pdf'), findsOneWidget);
    expect(find.text('1,2 Mo'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    expect(analyzeEnabled(tester), isTrue);
  });

  testWidgets('Analyser mon CV ouvre Vos compétences, Retour ramène ici', (
    tester,
  ) async {
    await pumpScreen(tester);
    await choose(tester, validPdf);

    await tapVisible(tester, find.byKey(CvUploadScreen.analyzeButtonKey));
    // pumpAndSettle attend la fin de l'animation de transition.
    await tester.pumpAndSettle();
    expect(find.text(skillsHeading), findsOneWidget);
    expect(find.text('Ajoutez votre CV'), findsNothing);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.text(skillsHeading), findsNothing);
    // Le fichier choisi est toujours là.
    expect(find.text('cv_candidat.pdf'), findsOneWidget);
  });

  testWidgets('« Importer un autre CV » ramène à l\'écran CV', (tester) async {
    await pumpScreen(tester);
    await choose(tester, validPdf);
    await tapVisible(tester, find.byKey(CvUploadScreen.analyzeButtonKey));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Importer un autre CV'));
    await tester.tap(find.text('Importer un autre CV'));
    await tester.pumpAndSettle();
    expect(find.text(skillsHeading), findsNothing);
    expect(find.text('Ajoutez votre CV'), findsOneWidget);
  });

  testWidgets('Mauvais type : message clair, bouton désactivé', (tester) async {
    await pumpScreen(tester);
    await choose(tester, imageFile);

    expect(find.text(CvFileRules.formatError), findsOneWidget);
    expect(find.text('photo.png'), findsNothing);
    expect(analyzeEnabled(tester), isFalse);
  });

  testWidgets('Fichier trop gros : message clair, bouton désactivé', (
    tester,
  ) async {
    await pumpScreen(tester);
    await choose(tester, hugeFile);

    expect(
      find.text(CvFileRules.tooLargeError(hugeFile.sizeInBytes)),
      findsOneWidget,
    );
    expect(find.textContaining('6 Mo'), findsOneWidget);
    expect(find.text('cv_lourd.pdf'), findsNothing);
    expect(analyzeEnabled(tester), isFalse);
  });

  testWidgets('Retrait du fichier : retour à l\'état initial', (tester) async {
    await pumpScreen(tester);
    await choose(tester, validPdf);
    expect(analyzeEnabled(tester), isTrue);

    await tapVisible(tester, find.byTooltip('Retirer le fichier'));

    expect(find.text('cv_candidat.pdf'), findsNothing);
    expect(find.text('Choisir un fichier'), findsOneWidget);
    expect(analyzeEnabled(tester), isFalse);
  });

  testWidgets('« Changer » remplace le fichier choisi', (tester) async {
    await pumpScreen(tester);
    await choose(tester, validPdf);

    picker.next = validDocx;
    await tapVisible(tester, find.text('Changer'));

    expect(find.text('cv_candidat.pdf'), findsNothing);
    expect(find.text('cv_v2.docx'), findsOneWidget);
    expect(find.text('350 Ko'), findsOneWidget);
    expect(analyzeEnabled(tester), isTrue);
  });

  testWidgets('Un fichier refusé après un bon retire le précédent', (
    tester,
  ) async {
    await pumpScreen(tester);
    await choose(tester, validPdf);

    picker.next = imageFile;
    await tapVisible(tester, find.text('Changer'));

    expect(find.text('cv_candidat.pdf'), findsNothing);
    expect(find.text(CvFileRules.formatError), findsOneWidget);
    expect(analyzeEnabled(tester), isFalse);
  });

  testWidgets('Annuler le sélecteur ne change rien', (tester) async {
    await pumpScreen(tester);
    await choose(tester, null);

    expect(picker.calls, 1);
    expect(find.text('Choisir un fichier'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    expect(analyzeEnabled(tester), isFalse);
  });

  testWidgets('Sélecteur en panne : message clair', (tester) async {
    await pumpScreen(tester);
    picker.shouldFail = true;
    await tapVisible(tester, find.byKey(CvUploadScreen.pickButtonKey));

    expect(find.text(CvFileRules.pickerError), findsOneWidget);
    expect(analyzeEnabled(tester), isFalse);
  });

  testWidgets('Ajout du CV respecte les règles de contenu', (tester) async {
    await pumpScreen(tester);
    await choose(tester, validPdf);

    // Mots interdits par CLAUDE.md, et promesses qu'on ne peut pas tenir.
    for (final word in [
      'vérifié',
      'passeport',
      'défi',
      'chiffré',
      'certifié',
    ]) {
      expect(find.textContaining(word), findsNothing, reason: word);
    }
    // Éléments de la maquette volontairement retirés.
    for (final removed in [
      'robot',
      'Sécurité',
      '10 Mo',
      'Dernière étape',
      'Passer pour',
      'pré-remplissons',
      'Déposez',
    ]) {
      expect(find.textContaining(removed), findsNothing, reason: removed);
    }
  });
}
