import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/auth/presentation/welcome_screen.dart';

void main() {
  // On teste l'écran dans un MaterialApp simple, sans AppTheme : en test,
  // il n'y a pas d'Internet et google_fonts ne pourrait pas télécharger
  // les polices. L'écran fonctionne quand même, avec la police par défaut.
  Future<void> pumpWelcome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
  }

  testWidgets('Bienvenue affiche le titre et les deux boutons', (tester) async {
    await pumpWelcome(tester);

    expect(find.text('Prouve ce que tu sais faire.'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('Bienvenue respecte les règles de contenu', (tester) async {
    await pumpWelcome(tester);

    // Phrase sur l'hébergement retirée, sélecteur de langue masqué.
    expect(find.textContaining('hébergées'), findsNothing);
    expect(find.text('العربية'), findsNothing);
    // Mots interdits par CLAUDE.md.
    for (final word in ['vérifié', 'passeport', 'défi']) {
      expect(find.textContaining(word), findsNothing);
    }
  });

  testWidgets("Créer un compte ouvre l'Inscription, Retour ramène ici", (
    tester,
  ) async {
    await pumpWelcome(tester);

    // Le bouton peut être sous le bas de l'écran : on fait défiler d'abord.
    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.tap(find.text('Créer un compte'));
    // pumpAndSettle attend la fin de l'animation de transition.
    await tester.pumpAndSettle();

    expect(find.text('Créez votre compte'), findsOneWidget);
    expect(find.text('Prouve ce que tu sais faire.'), findsNothing);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();

    expect(find.text('Prouve ce que tu sais faire.'), findsOneWidget);
    expect(find.text('Créez votre compte'), findsNothing);
  });

  // Petit raccourci : fait défiler jusqu'au texte, le touche, puis attend
  // la fin de l'animation de transition.
  Future<void> tapAndSettle(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('Se connecter ouvre la Connexion, Retour ramène ici', (
    tester,
  ) async {
    await pumpWelcome(tester);

    await tapAndSettle(tester, 'Se connecter');
    expect(find.text('Bon retour'), findsOneWidget);
    expect(find.text('Prouve ce que tu sais faire.'), findsNothing);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Prouve ce que tu sais faire.'), findsOneWidget);
  });

  testWidgets('Connexion → Créer un compte → Retour ramène à Bienvenue', (
    tester,
  ) async {
    await pumpWelcome(tester);

    await tapAndSettle(tester, 'Se connecter');
    // Lien « Créer un compte » de la Connexion (Bienvenue est cachée
    // dessous, find.text ne voit que l'écran affiché).
    await tapAndSettle(tester, 'Créer un compte');
    expect(find.text('Créez votre compte'), findsOneWidget);
    expect(find.text('Bon retour'), findsNothing);

    // pushReplacement : la Connexion a été remplacée, Retour mène donc
    // directement à Bienvenue.
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Prouve ce que tu sais faire.'), findsOneWidget);
    expect(find.text('Créez votre compte'), findsNothing);
    expect(find.text('Bon retour'), findsNothing);
  });

  testWidgets('Inscription → Se connecter → Retour ramène à Bienvenue', (
    tester,
  ) async {
    await pumpWelcome(tester);

    await tapAndSettle(tester, 'Créer un compte');
    // Lien « Se connecter » de l'Inscription.
    await tapAndSettle(tester, 'Se connecter');
    expect(find.text('Bon retour'), findsOneWidget);
    expect(find.text('Créez votre compte'), findsNothing);

    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    expect(find.text('Prouve ce que tu sais faire.'), findsOneWidget);
    expect(find.text('Bon retour'), findsNothing);
  });
}
