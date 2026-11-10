import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../data/auth_session.dart';
import '../domain/auth_failure.dart';
import 'auth_navigation.dart';
import 'auth_validators.dart';
import 'login_screen.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/auth_switch_link.dart';
import 'widgets/labeled_text_field.dart';
import 'widgets/password_field.dart';
import 'widgets/terms_checkbox_field.dart';

/// Écran 2 : Inscription.
///
/// Le candidat saisit son nom, son e-mail et un mot de passe. Le formulaire
/// est d'abord contrôlé sur le téléphone, puis envoyé à POST /auth/register.
/// L'API crée le compte sans donner de jeton : l'écran enchaîne donc
/// aussitôt avec POST /auth/login, puis ouvre l'écran Ajout du CV.
///
/// StatefulWidget, car l'écran retient le texte saisi, le moment où les
/// erreurs commencent à s'afficher et l'état de l'envoi.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.onSignIn, this.session});

  /// Action du lien « Se connecter ». Par défaut, il ouvre la Connexion à
  /// la place de l'Inscription (voir _openLogin).
  final VoidCallback? onSignIn;

  /// Connexion à l'API. Les tests en donnent une fausse ; sinon, la vraie.
  final AuthSession? session;

  // Clés qui permettent aux tests de retrouver chaque champ.
  static const nameFieldKey = Key('register_name');
  static const emailFieldKey = Key('register_email');
  static const passwordFieldKey = Key('register_password');

  /// Message quand le compte est créé mais que la connexion automatique
  /// échoue (par exemple, limite d'essais atteinte entre les deux appels).
  static const accountCreatedMessage =
      'Compte créé. Connectez-vous pour continuer.';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  /// Clé du formulaire : elle permet de valider tous les champs d'un coup.
  final _formKey = GlobalKey<FormState>();

  /// Contrôleurs : ils donnent accès au texte saisi pour l'envoyer.
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  /// Au début, aucune erreur ne s'affiche : on ne signale rien avant que le
  /// candidat ait essayé. Après le premier appui sur « Créer mon compte »,
  /// les messages se mettent à jour à chaque modification.
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  /// Vrai pendant les appels à l'API : le bouton est alors désactivé.
  bool _isSubmitting = false;

  AuthSession get _session => widget.session ?? defaultAuthSession;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // « Terminé » sur le clavier pendant un envoi : on ignore.
    if (_isSubmitting) return;

    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    // Ferme le clavier pour que le message éventuel soit bien visible.
    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    // Espaces retirés autour du nom et de l'e-mail, jamais dans le mot de
    // passe : un espace peut en faire partie.
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    String? error;
    var accountCreated = false;
    try {
      await _session.register(
        fullName: _nameController.text.trim(),
        email: email,
        password: password,
      );
      accountCreated = true;
      await _session.login(email: email, password: password);
    } on AuthException catch (e) {
      error = e.message;
    } catch (_) {
      // Erreur imprévue : message générique, jamais le détail technique.
      error = AuthFailure.unknown.message;
    }

    // L'écran a pu être fermé pendant l'attente.
    if (!mounted) return;

    if (error == null) {
      // Succès : le bouton reste désactivé pendant l'animation.
      openHomeAfterSignIn(context);
      return;
    }

    if (accountCreated) {
      // Le compte existe : réessayer l'inscription donnerait un 409. On
      // envoie donc vers la Connexion, avec l'e-mail déjà rempli.
      showAuthMessage(context, RegisterScreen.accountCreatedMessage);
      _openLogin(initialEmail: email);
      return;
    }

    setState(() => _isSubmitting = false);
    showAuthMessage(context, error);
  }

  /// Remplace l'Inscription par la Connexion (pushReplacement) : l'écran
  /// en dessous reste Bienvenue, et le bouton retour y ramène directement.
  /// Avec un simple push, les écrans s'empileraient à chaque aller-retour.
  void _openLogin({String? initialEmail}) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            LoginScreen(session: widget.session, initialEmail: initialEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      appBarTitle: 'Inscription',
      heading: 'Créez votre compte',
      subtitle: 'Quelques informations suffisent pour commencer.',
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        // AutofillGroup : le téléphone peut proposer le nom et l'e-mail
        // qu'il connaît, et enregistrer le mot de passe.
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabeledTextField(
                fieldKey: RegisterScreen.nameFieldKey,
                controller: _nameController,
                label: 'Nom complet',
                hintText: 'Prénom et nom',
                prefixIcon: Icons.badge_outlined,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: AuthValidators.fullName,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                fieldKey: RegisterScreen.emailFieldKey,
                controller: _emailController,
                label: 'Adresse e-mail',
                hintText: 'nom@exemple.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                enableSuggestions: false,
                validator: AuthValidators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                fieldKey: RegisterScreen.passwordFieldKey,
                controller: _passwordController,
                helperText:
                    '${AuthValidators.minPasswordLength} caractères minimum',
                // newPassword : le gestionnaire de mots de passe du
                // téléphone peut en proposer un et l'enregistrer.
                autofillHints: const [AutofillHints.newPassword],
                validator: AuthValidators.password,
                // « Terminé » sur le clavier = appui sur le bouton.
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.md),
              const TermsCheckboxField(),
              const SizedBox(height: AppSpacing.lg),
              AuthSubmitButton(
                label: 'Créer mon compte',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthSwitchLink(
                question: 'Déjà inscrit ?',
                actionLabel: 'Se connecter',
                onPressed: widget.onSignIn ?? _openLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
