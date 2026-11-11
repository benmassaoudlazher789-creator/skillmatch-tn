import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/auth/data/auth_session.dart';
import 'package:skillmatch_tn/features/auth/domain/auth_failure.dart';
import 'package:skillmatch_tn/features/auth/domain/auth_token.dart';
import 'package:skillmatch_tn/features/auth/presentation/auth_validators.dart';
import 'package:skillmatch_tn/features/auth/presentation/login_screen.dart';
import 'package:skillmatch_tn/features/auth/presentation/widgets/auth_submit_button.dart';

import 'support/fake_auth.dart';

void main() {
  // Même principe que les autres tests : MaterialApp sans AppTheme, car
  // google_fonts n'a pas Internet pendant les tests.
  // Une fausse session est toujours fournie : aucun appel réseau réel.
  Future<void> pumpLogin(
    WidgetTester tester, {
    AuthSession? session,
    String? initialEmail,
  }) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          session: session ?? fakeSession().session,
          initialEmail: initialEmail,
        ),
      ),
    );
  }

  /// Le bouton principal est-il actif ?
  bool isButtonEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

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
  // Titre de l'écran Ajout du CV, ouvert après une connexion réussie.
  const cvHeading = 'Ajoutez votre CV';

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

  testWidgets('Formulaire vide : une erreur sous chaque champ, rien envoyé', (
    tester,
  ) async {
    final fake = fakeSession();
    await pumpLogin(tester, session: fake.session);
    await submit(tester);

    expect(find.text(emailEmptyError), findsOneWidget);
    expect(find.text(passwordEmptyError), findsOneWidget);
    expect(fake.api.loginCalls, isEmpty);
  });

  testWidgets('E-mail mal formé refusé, mot de passe non vide accepté', (
    tester,
  ) async {
    final fake = fakeSession();
    await pumpLogin(tester, session: fake.session);
    await fillFields(tester, email: 'candidat@exemple');
    await submit(tester);

    expect(find.text(emailFormatError), findsOneWidget);
    expect(find.text(passwordEmptyError), findsNothing);
    expect(fake.api.loginCalls, isEmpty);
  });

  testWidgets(
    "Formulaire valide : bouton désactivé pendant l'envoi, puis écran du CV",
    (tester) async {
      final fake = fakeSession();
      // Le faux serveur attend notre signal pour répondre.
      final response = Completer<AuthToken>();
      fake.api.onLogin = () => response.future;

      await pumpLogin(tester, session: fake.session);
      // Espaces autour de l'e-mail : ils doivent être retirés à l'envoi.
      // Un mot de passe court suffit : seule l'absence est refusée ici.
      await fillFields(tester, email: '  candidat@exemple.com ');
      await submit(tester);

      // Pendant l'envoi : bouton désactivé, indicateur visible.
      expect(isButtonEnabled(tester), isFalse);
      expect(find.byKey(AuthSubmitButton.loadingKey), findsOneWidget);
      // Un second appui sur le bouton désactivé n'envoie rien de plus.
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(fake.api.loginCalls, hasLength(1));
      expect(fake.api.loginCalls.single.email, 'candidat@exemple.com');
      expect(fake.api.loginCalls.single.password, 'abc');

      response.complete(fakeToken);
      await tester.pumpAndSettle();

      expect(fake.store.token, fakeToken.accessToken);
      expect(find.text(cvHeading), findsOneWidget);
      expect(find.text('Bon retour'), findsNothing);
      // Le jeton ne s'affiche nulle part.
      expect(find.textContaining(fakeToken.accessToken), findsNothing);
    },
  );

  // Un test par raison d'échec : message affiché, bouton réactivé, aucun
  // changement d'écran, aucun jeton rangé.
  for (final failure in [
    AuthFailure.invalidCredentials,
    AuthFailure.tooManyAttempts,
    AuthFailure.network,
    AuthFailure.unknown,
  ]) {
    testWidgets('Échec ${failure.name} : message en français, on reste ici', (
      tester,
    ) async {
      final fake = fakeSession();
      fake.api.onLogin = () async => throw AuthException(failure);

      await pumpLogin(tester, session: fake.session);
      await fillFields(tester);
      await submit(tester);
      await tester.pump();

      expect(find.text(failure.message), findsOneWidget);
      expect(isButtonEnabled(tester), isTrue);
      expect(find.byKey(AuthSubmitButton.loadingKey), findsNothing);
      expect(find.text('Bon retour'), findsOneWidget);
      expect(fake.store.token, isNull);
    });
  }

  testWidgets('Jeton impossible à ranger : message dédié, on reste ici', (
    tester,
  ) async {
    final fake = fakeSession();
    fake.store.failOnSave = true;

    await pumpLogin(tester, session: fake.session);
    await fillFields(tester);
    await submit(tester);
    await tester.pump();

    expect(find.text(AuthFailure.storage.message), findsOneWidget);
    expect(find.text(cvHeading), findsNothing);
    expect(find.textContaining(fakeToken.accessToken), findsNothing);
  });

  testWidgets('E-mail reçu en paramètre : déjà rempli', (tester) async {
    await pumpLogin(tester, initialEmail: 'candidat@exemple.com');

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(LoginScreen.emailFieldKey),
        matching: find.byType(TextField),
      ),
    );
    expect(field.controller?.text, 'candidat@exemple.com');
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

  testWidgets('Sans message d\'ouverture, aucun bandeau', (tester) async {
    await pumpLogin(tester);
    expect(find.text(sessionExpiredMessage), findsNothing);
  });

  testWidgets('Session expirée : le message reste affiché en haut', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          session: fakeSession().session,
          initialMessage: sessionExpiredMessage,
        ),
      ),
    );
    // Bien après la durée d'un SnackBar (4 s) : le bandeau est toujours là.
    await tester.pump(const Duration(seconds: 10));

    expect(find.text(sessionExpiredMessage), findsOneWidget);
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
