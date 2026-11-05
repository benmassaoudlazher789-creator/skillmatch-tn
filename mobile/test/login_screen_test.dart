import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/auth/presentation/auth_validators.dart';
import 'package:skillmatch_tn/features/auth/presentation/login_screen.dart';

void main() {
  // Même principe que les autres tests : MaterialApp sans AppTheme, car
  // google_fonts n'a pas Internet pendant les tests.
  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
  }

  // Valeurs fictives, propres aux tests (pas de données des maquettes).
  Future<void> fillFields(
    WidgetTester tester, {
    String email = 'candidat@exemple.com',
    String password = 'abc',
  }) async {
    await tester.enterText(find.byKey(LoginScreen.emailFieldKey), email);
    await tester.enterText(find.byKey(LoginScreen.passwordFieldKey), password);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  // Le texte « Se connecter » n'apparaît qu'une fois ici : sur le bouton.
  Future<void> submit(WidgetTester tester) =>
      tapVisible(tester, find.text('Se connecter'));

  const emailEmptyError = 'Veuillez saisir votre adresse e-mail.';
  const emailFormatError =
      'Adresse e-mail invalide (exemple : nom@exemple.com).';
  const passwordEmptyError = 'Veuillez saisir votre mot de passe.';
  const successMessage = "Connexion bientôt disponible : rien n'a été envoyé.";

  testWidgets('Connexion affiche le titre, les champs et les actions', (
    tester,
  ) async {
    await pumpLogin(tester);

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Bon retour'), findsOneWidget);
    expect(
      find.text('Connectez-vous pour retrouver vos offres et votre profil.'),
      findsOneWidget,
    );
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('Mot de passe oublié ?'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    expect(find.text('Pas de compte ?'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
    // La règle des 8 caractères ne concerne que l'Inscription.
    expect(find.text('8 caractères minimum'), findsNothing);

    // Bouton retour : zone tactile d'au moins 48 × 48 px.
    final back = find.ancestor(
      of: find.byIcon(Icons.arrow_back_rounded),
      matching: find.byType(IconButton),
    );
    final size = tester.getSize(back);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('Connexion respecte les règles de contenu', (tester) async {
    await pumpLogin(tester);

    // Mots interdits par CLAUDE.md.
    for (final word in ['vérifié', 'passeport', 'défi']) {
      expect(find.textContaining(word), findsNothing);
    }
    // Éléments de la maquette volontairement retirés.
    for (final removed in [
      'certifiée',
      'Talents',
      '1 420',
      'GitHub',
      'LinkedIn',
      'continuer avec',
      'sarah',
      'insat',
      'esprit',
    ]) {
      expect(find.textContaining(removed), findsNothing, reason: removed);
    }
  });

  testWidgets('Formulaire vide : une erreur sous chaque champ', (tester) async {
    await pumpLogin(tester);
    await submit(tester);

    expect(find.text(emailEmptyError), findsOneWidget);
    expect(find.text(passwordEmptyError), findsOneWidget);
    expect(find.text(successMessage), findsNothing);
  });

  testWidgets('E-mail mal formé refusé, mot de passe non vide accepté', (
    tester,
  ) async {
    await pumpLogin(tester);
    await fillFields(tester, email: 'candidat@exemple');
    await submit(tester);

    expect(find.text(emailFormatError), findsOneWidget);
    expect(find.text(passwordEmptyError), findsNothing);
    expect(find.text(successMessage), findsNothing);
  });

  testWidgets('Formulaire valide : message temporaire, rien envoyé', (
    tester,
  ) async {
    await pumpLogin(tester);
    // Un mot de passe court suffit ici : seule l'absence de mot de passe
    // est refusée à la Connexion.
    await fillFields(tester, password: 'abc');
    await submit(tester);

    expect(find.text(emailEmptyError), findsNothing);
    expect(find.text(passwordEmptyError), findsNothing);
    expect(find.text(successMessage), findsOneWidget);
  });

  testWidgets('Le bouton œil affiche puis masque le mot de passe', (
    tester,
  ) async {
    await pumpLogin(tester);

    bool isObscured() => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(LoginScreen.passwordFieldKey),
            matching: find.byType(TextField),
          ),
        )
        .obscureText;

    expect(isObscured(), isTrue);
    await tapVisible(tester, find.byTooltip('Afficher le mot de passe'));
    expect(isObscured(), isFalse);
    await tapVisible(tester, find.byTooltip('Masquer le mot de passe'));
    expect(isObscured(), isTrue);
  });

  testWidgets('« Mot de passe oublié ? » est un texte simple, sans action', (
    tester,
  ) async {
    await pumpLogin(tester);
    final forgot = find.text('Mot de passe oublié ?');

    // Aucun bouton ni zone cliquable autour du texte.
    expect(
      find.ancestor(of: forgot, matching: find.byType(InkWell)),
      findsNothing,
    );
    expect(
      find.ancestor(of: forgot, matching: find.byType(ButtonStyleButton)),
      findsNothing,
    );

    // Le toucher ne change rien : pas de message, pas de nouvel écran.
    await tester.ensureVisible(forgot);
    await tester.tap(forgot, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text('Bon retour'), findsOneWidget);
  });

  group('AuthValidators.passwordRequired', () {
    test('mot de passe : seulement non vide', () {
      expect(AuthValidators.passwordRequired(null), isNotNull);
      expect(AuthValidators.passwordRequired(''), isNotNull);
      expect(AuthValidators.passwordRequired('a'), isNull);
    });
  });
}
