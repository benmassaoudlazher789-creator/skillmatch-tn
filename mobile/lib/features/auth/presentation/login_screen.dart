import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/widgets/info_banner.dart';
import '../data/auth_session.dart';
import '../domain/auth_failure.dart';
import 'auth_navigation.dart';
import 'auth_validators.dart';
import 'register_screen.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_submit_button.dart';
import 'widgets/auth_switch_link.dart';
import 'widgets/labeled_text_field.dart';
import 'widgets/password_field.dart';

/// Écran 3 : Connexion.
///
/// Le candidat saisit son e-mail et son mot de passe. Le formulaire est
/// d'abord contrôlé sur le téléphone, puis envoyé à POST /auth/login. En
/// cas de succès, le jeton est rangé sur l'appareil et l'écran Ajout du CV
/// s'ouvre.
///
/// Même structure que l'Inscription : AuthScaffold pour la mise en page,
/// LabeledTextField et PasswordField pour les champs.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onCreateAccount,
    this.session,
    this.initialEmail,
    this.initialMessage,
  });

  /// Action du lien « Créer un compte ». Par défaut, il ouvre l'Inscription
  /// à la place de la Connexion (voir _openRegister).
  final VoidCallback? onCreateAccount;

  /// Connexion à l'API. Les tests en donnent une fausse ; sinon, la vraie.
  final AuthSession? session;

  /// E-mail déjà rempli (après une inscription dont la connexion a échoué).
  final String? initialEmail;

  /// Message affiché en haut du formulaire à l'ouverture (par exemple
  /// « Session expirée, reconnectez-vous »), ou null.
  ///
  /// Un bandeau plutôt qu'un message en bas de l'écran : il reste visible
  /// tant que le candidat n'est pas reconnecté, au lieu de disparaître au
  /// bout de quelques secondes.
  final String? initialMessage;

  // Clés qui permettent aux tests de retrouver chaque champ.
  static const emailFieldKey = Key('login_email');
  static const passwordFieldKey = Key('login_password');

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Clé du formulaire : elle permet de valider tous les champs d'un coup.
  final _formKey = GlobalKey<FormState>();

  /// Contrôleurs : ils donnent accès au texte saisi pour l'envoyer.
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();

  /// Pas d'erreur affichée avant le premier essai (comme à l'Inscription).
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  /// Vrai pendant l'appel à l'API : le bouton est alors désactivé.
  bool _isSubmitting = false;

  AuthSession get _session => widget.session ?? defaultAuthSession;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
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

    String? error;
    try {
      await _session.login(
        // Espaces retirés autour de l'e-mail, mais jamais dans le mot de
        // passe : un espace peut en faire partie.
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      error = e.message;
    } catch (_) {
      // Erreur imprévue : message générique, jamais le détail technique.
      error = AuthFailure.unknown.message;
    }

    // L'écran a pu être fermé pendant l'attente.
    if (!mounted) return;

    if (error != null) {
      setState(() => _isSubmitting = false);
      showAuthMessage(context, error);
      return;
    }
    // Succès : _isSubmitting reste vrai, le bouton reste désactivé pendant
    // l'animation vers l'écran suivant.
    openHomeAfterSignIn(context);
  }

  /// Remplace la Connexion par l'Inscription (pushReplacement) : l'écran
  /// en dessous reste Bienvenue, et le bouton retour y ramène directement.
  void _openRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(session: widget.session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return AuthScaffold(
      appBarTitle: 'Connexion',
      heading: 'Bon retour',
      subtitle: 'Connectez-vous pour retrouver vos offres et votre profil.',
      child: Form(
        key: _formKey,
        autovalidateMode: _autovalidateMode,
        // AutofillGroup : le téléphone peut remplir l'e-mail et le mot de
        // passe qu'il a enregistrés.
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.initialMessage case final message?) ...[
                // liveRegion : le lecteur d'écran lit le message à
                // l'ouverture de l'écran.
                Semantics(liveRegion: true, child: InfoBanner.neutral(message)),
                const SizedBox(height: AppSpacing.lg),
              ],
              LabeledTextField(
                fieldKey: LoginScreen.emailFieldKey,
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
                fieldKey: LoginScreen.passwordFieldKey,
                controller: _passwordController,
                autofillHints: const [AutofillHints.password],
                validator: AuthValidators.passwordRequired,
                // « Terminé » sur le clavier = appui sur le bouton.
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Texte simple, volontairement sans action : la réinitialisation
              // du mot de passe n'existe pas encore. En gris (et non en vert)
              // pour ne pas ressembler à un lien.
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Mot de passe oublié ?',
                  style: text.bodySmall?.copyWith(color: AppColors.carbon),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthSubmitButton(
                label: 'Se connecter',
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              AuthSwitchLink(
                question: 'Pas de compte ?',
                actionLabel: 'Créer un compte',
                onPressed: widget.onCreateAccount ?? _openRegister,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
