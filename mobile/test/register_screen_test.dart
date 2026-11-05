import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/auth/presentation/auth_validators.dart';
import 'package:skillmatch_tn/features/auth/presentation/register_screen.dart';
import 'package:skillmatch_tn/features/auth/presentation/widgets/terms_checkbox_field.dart';

void main() {
  // Même principe que widget_test.dart : MaterialApp sans AppTheme, car
  // google_fonts n'a pas Internet pendant les tests.
  Future<void> pumpRegister(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));
  }

  // Valeurs fictives, propres aux tests (pas de données des maquettes).
  Future<void> fillFields(
    WidgetTester tester, {
    String name = 'Candidat Test',
    String email = 'candidat@exemple.com',
    String password = 'abcdefgh', // exactement 8 caractères
  }) async {
    await tester.enterText(find.byKey(RegisterScreen.nameFieldKey), name);
    await tester.enterText(find.byKey(RegisterScreen.emailFieldKey), email);
    await tester.enterText(
      find.byKey(RegisterScreen.passwordFieldKey),
      password,
    );
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  Future<void> submit(WidgetTester tester) =>
      tapVisible(tester, find.text('Créer mon compte'));

  const nameError = 'Veuillez saisir votre nom complet.';
  const emailEmptyError = 'Veuillez saisir votre adresse e-mail.';
  const emailFormatError =
      'Adresse e-mail invalide (exemple : nom@exemple.com).';
  const passwordEmptyError = 'Veuillez saisir un mot de passe.';
  const passwordShortError =
      'Le mot de passe doit contenir au moins 8 caractères.';
  const termsError = 'Vous devez accepter les conditions pour créer un compte.';
  const successMessage =
      "Inscription bientôt disponible : rien n'a été envoyé.";

  testWidgets('Inscription affiche le titre, les champs et les actions', (
    tester,
  ) async {
    await pumpRegister(tester);

    expect(find.text('Inscription'), findsOneWidget);
    expect(find.text('Créez votre compte'), findsOneWidget);
    expect(
      find.text('Quelques informations suffisent pour commencer.'),
      findsOneWidget,
    );
    expect(find.text('Nom complet'), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.text('8 caractères minimum'), findsOneWidget);
    expect(find.text(TermsCheckboxField.label), findsOneWidget);
    expect(find.text('Créer mon compte'), findsOneWidget);
    expect(find.text('Déjà inscrit ?'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);

    // Bouton retour : zone tactile d'au moins 48 × 48 px.
    final back = find.ancestor(
      of: find.byIcon(Icons.arrow_back_rounded),
      matching: find.byType(IconButton),
    );
    final size = tester.getSize(back);
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });

  testWidgets('Inscription respecte les règles de contenu', (tester) async {
    await pumpRegister(tester);

    // Mots interdits par CLAUDE.md.
    for (final word in ['vérifié', 'passeport', 'défi']) {
      expect(find.textContaining(word), findsNothing);
    }
    // Éléments de la maquette volontairement retirés.
    expect(find.textContaining('opportunités'), findsNothing);
    expect(find.textContaining('Avantages'), findsNothing);
    expect(find.textContaining('recrutements'), findsNothing);
    // Données d'exemple de la maquette non reprises.
    expect(find.textContaining('Yassine'), findsNothing);
    expect(find.textContaining('insat'), findsNothing);
  });

  testWidgets(
    'Formulaire vide : une erreur sous chaque champ et sous la case',
    (tester) async {
      await pumpRegister(tester);
      await submit(tester);

      expect(find.text(nameError), findsOneWidget);
      expect(find.text(emailEmptyError), findsOneWidget);
      expect(find.text(passwordEmptyError), findsOneWidget);
      expect(find.text(termsError), findsOneWidget);
      expect(find.text(successMessage), findsNothing);
    },
  );

  testWidgets('E-mail mal formé et mot de passe trop court sont refusés', (
    tester,
  ) async {
    await pumpRegister(tester);
    await fillFields(tester, email: 'candidat@exemple', password: 'abcdefg');
    await submit(tester);

    expect(find.text(nameError), findsNothing);
    expect(find.text(emailFormatError), findsOneWidget);
    expect(find.text(passwordShortError), findsOneWidget);
    expect(find.text(successMessage), findsNothing);
  });

  testWidgets('Case non cochée bloque, puis formulaire valide : message', (
    tester,
  ) async {
    await pumpRegister(tester);
    await fillFields(tester);

    await submit(tester);
    expect(find.text(termsError), findsOneWidget);
    expect(find.text(successMessage), findsNothing);

    // Toucher le texte coche la case et fait disparaître l'erreur.
    await tapVisible(tester, find.text(TermsCheckboxField.label));
    expect(find.text(termsError), findsNothing);

    await submit(tester);
    expect(find.text(successMessage), findsOneWidget);
  });

  testWidgets('Le bouton œil affiche puis masque le mot de passe', (
    tester,
  ) async {
    await pumpRegister(tester);

    bool isObscured() => tester
        .widget<TextField>(
          find.descendant(
            of: find.byKey(RegisterScreen.passwordFieldKey),
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

  testWidgets("Se connecter remplace l'Inscription par la Connexion", (
    tester,
  ) async {
    await pumpRegister(tester);
    await tester.ensureVisible(find.text('Se connecter'));
    await tester.tap(find.text('Se connecter'));
    // pumpAndSettle attend la fin de l'animation de transition.
    await tester.pumpAndSettle();

    expect(find.text('Bon retour'), findsOneWidget);
    expect(find.text('Créez votre compte'), findsNothing);
  });

  // Tests unitaires des règles, sans écran : rapides et précis.
  group('AuthValidators', () {
    test('nom : vide ou espaces refusés', () {
      expect(AuthValidators.fullName(null), isNotNull);
      expect(AuthValidators.fullName(''), isNotNull);
      expect(AuthValidators.fullName('   '), isNotNull);
      expect(AuthValidators.fullName('Candidat Test'), isNull);
    });

    test('e-mail : format contrôlé', () {
      expect(AuthValidators.email('candidat@exemple.com'), isNull);
      expect(AuthValidators.email('  candidat@exemple.com  '), isNull);
      for (final bad in [
        '',
        'candidat',
        'candidat@',
        'candidat@exemple',
        '@exemple.com',
        'can didat@exemple.com',
        'candidat@exemple.c',
      ]) {
        expect(AuthValidators.email(bad), isNotNull, reason: bad);
      }
    });

    test('mot de passe : 8 caractères minimum', () {
      expect(AuthValidators.password(''), isNotNull);
      expect(AuthValidators.password('abcdefg'), isNotNull);
      expect(AuthValidators.password('abcdefgh'), isNull);
    });

    test('conditions : la case doit être cochée', () {
      expect(AuthValidators.termsAccepted(null), isNotNull);
      expect(AuthValidators.termsAccepted(false), isNotNull);
      expect(AuthValidators.termsAccepted(true), isNull);
    });
  });
}
