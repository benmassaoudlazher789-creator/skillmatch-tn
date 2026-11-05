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

  testWidgets("Créer un compte ouvre l'Inscription, Retour ramène ici",
      (tester) async {
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

  testWidgets('Se connecter affiche un message temporaire', (tester) async {
    await pumpWelcome(tester);

    await tester.ensureVisible(find.text('Se connecter'));
    await tester.tap(find.text('Se connecter'));
    await tester.pump();
    expect(find.textContaining('à venir'), findsOneWidget);
  });
}
