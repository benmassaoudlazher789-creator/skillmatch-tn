import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/auth/data/auth_session.dart';
import 'package:skillmatch_tn/features/auth/domain/auth_failure.dart';
import 'package:skillmatch_tn/features/auth/presentation/auth_validators.dart';
import 'package:skillmatch_tn/features/auth/presentation/login_screen.dart';
import 'package:skillmatch_tn/features/auth/presentation/register_screen.dart';
import 'package:skillmatch_tn/features/auth/presentation/widgets/auth_submit_button.dart';
import 'package:skillmatch_tn/features/auth/presentation/widgets/terms_checkbox_field.dart';

import 'support/fake_auth.dart';

void main() {
  // Même principe que widget_test.dart : MaterialApp sans AppTheme, car
  // google_fonts n'a pas Internet pendant les tests.
  // Une fausse session est toujours fournie : aucun appel réseau réel.
  Future<void> pumpRegister(WidgetTester tester, {AuthSession? session}) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: RegisterScreen(session: session ?? fakeSession().session),
      ),
    );
  }

  /// Le bouton principal est-il actif ?
  bool isButtonEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

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
  // Titre de l'écran Ajout du CV, ouvert après une inscription réussie.
  const cvHeading = 'Ajoutez votre CV';

  /// Remplit tout le formulaire et coche la case des conditions.
  Future<void> fillValidForm(WidgetTester tester) async {
    await fillFields(tester);
    await tapVisible(tester, find.text(TermsCheckboxField.label));
  }

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
      final fake = fakeSession();
      await pumpRegister(tester, session: fake.session);
      await submit(tester);

      expect(find.text(nameError), findsOneWidget);
      expect(find.text(emailEmptyError), findsOneWidget);
      expect(find.text(passwordEmptyError), findsOneWidget);
      expect(find.text(termsError), findsOneWidget);
      expect(fake.api.registerCalls, isEmpty);
    },
  );

  testWidgets('E-mail mal formé et mot de passe trop court sont refusés', (
    tester,
  ) async {
    final fake = fakeSession();
    await pumpRegister(tester, session: fake.session);
    await fillFields(tester, email: 'candidat@exemple', password: 'abcdefg');
    await submit(tester);

    expect(find.text(nameError), findsNothing);
    expect(find.text(emailFormatError), findsOneWidget);
    expect(find.text(passwordShortError), findsOneWidget);
    expect(fake.api.registerCalls, isEmpty);
  });

  testWidgets('Case non cochée bloque, rien envoyé', (tester) async {
    final fake = fakeSession();
    await pumpRegister(tester, session: fake.session);
    await fillFields(tester);

    await submit(tester);
    expect(find.text(termsError), findsOneWidget);
    expect(fake.api.registerCalls, isEmpty);

    // Toucher le texte coche la case et fait disparaître l'erreur.
    await tapVisible(tester, find.text(TermsCheckboxField.label));
    expect(find.text(termsError), findsNothing);
  });

  testWidgets("Formulaire valide : inscription, connexion, puis écran du CV", (
    tester,
  ) async {
    final fake = fakeSession();
    // Le faux serveur attend notre signal pour répondre à l'inscription.
    final response = Completer<void>();
    fake.api.onRegister = () => response.future;

    await pumpRegister(tester, session: fake.session);
    await fillFields(tester, name: '  Candidat Test ');
    await tapVisible(tester, find.text(TermsCheckboxField.label));
    await submit(tester);

    // Pendant l'envoi : bouton désactivé, indicateur visible, un seul appel.
    expect(isButtonEnabled(tester), isFalse);
    expect(find.byKey(AuthSubmitButton.loadingKey), findsOneWidget);
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(fake.api.registerCalls, hasLength(1));

    response.complete();
    await tester.pumpAndSettle();

    final sent = fake.api.registerCalls.single;
    expect(sent.fullName, 'Candidat Test');
    expect(sent.email, 'candidat@exemple.com');
    expect(sent.password, 'abcdefgh');
    // Connexion automatique avec les mêmes identifiants.
    expect(fake.api.loginCalls.single.email, 'candidat@exemple.com');
    expect(fake.api.loginCalls.single.password, 'abcdefgh');
    expect(fake.store.token, fakeToken.accessToken);
    expect(find.text(cvHeading), findsOneWidget);
    expect(find.textContaining(fakeToken.accessToken), findsNothing);
  });

  // Échecs de l'inscription elle-même : message, bouton réactivé, pas de
  // connexion tentée, on reste sur l'écran.
  for (final failure in [
    AuthFailure.emailAlreadyUsed,
    AuthFailure.tooManyAttempts,
    AuthFailure.network,
  ]) {
    testWidgets('Échec ${failure.name} : message en français, on reste ici', (
      tester,
    ) async {
      final fake = fakeSession();
      fake.api.onRegister = () async => throw AuthException(failure);

      await pumpRegister(tester, session: fake.session);
      await fillValidForm(tester);
      await submit(tester);
      await tester.pump();

      expect(find.text(failure.message), findsOneWidget);
      expect(isButtonEnabled(tester), isTrue);
      expect(fake.api.loginCalls, isEmpty);
      expect(find.text('Créez votre compte'), findsOneWidget);
    });
  }

  testWidgets("400 : le message de l'API est affiché", (tester) async {
    final fake = fakeSession();
    fake.api.onRegister = () async => throw const AuthException(
      AuthFailure.invalidInput,
      serverMessage: 'Le nom complet est obligatoire.',
    );

    await pumpRegister(tester, session: fake.session);
    await fillValidForm(tester);
    await submit(tester);
    await tester.pump();

    expect(find.text('Le nom complet est obligatoire.'), findsOneWidget);
  });

  testWidgets(
    'Compte créé mais connexion en échec : Connexion avec e-mail rempli',
    (tester) async {
      final fake = fakeSession();
      fake.api.onLogin = () async =>
          throw const AuthException(AuthFailure.tooManyAttempts);

      await pumpRegister(tester, session: fake.session);
      await fillValidForm(tester);
      await submit(tester);
      await tester.pumpAndSettle();

      expect(find.text(RegisterScreen.accountCreatedMessage), findsOneWidget);
      expect(find.text('Bon retour'), findsOneWidget);
      expect(find.text('Créez votre compte'), findsNothing);
      final emailField = tester.widget<TextField>(
        find.descendant(
          of: find.byKey(LoginScreen.emailFieldKey),
          matching: find.byType(TextField),
        ),
      );
      expect(emailField.controller?.text, 'candidat@exemple.com');
      expect(fake.store.token, isNull);
    },
  );

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
