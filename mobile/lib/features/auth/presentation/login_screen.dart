import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'auth_validators.dart';
import 'register_screen.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_switch_link.dart';
import 'widgets/labeled_text_field.dart';
import 'widgets/password_field.dart';

/// Écran 3 : Connexion.
///
/// Le candidat saisit son e-mail et son mot de passe. L'API n'existe pas
/// encore : on vérifie seulement le formulaire sur le téléphone, et RIEN
/// n'est envoyé.
///
/// Même structure que l'Inscription : AuthScaffold pour la mise en page,
/// LabeledTextField et PasswordField pour les champs.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.onCreateAccount});

  /// Action du lien « Créer un compte ». Par défaut, il ouvre l'Inscription
  /// à la place de la Connexion (voir _openRegister).
  final VoidCallback? onCreateAccount;

  // Clés qui permettent aux tests de retrouver chaque champ.
  static const emailFieldKey = Key('login_email');
  static const passwordFieldKey = Key('login_password');

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Clé du formulaire : elle permet de valider tous les champs d'un coup.
  final _formKey = GlobalKey<FormState>();

  /// Pas d'erreur affichée avant le premier essai (comme à l'Inscription).
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  void _submit() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }
    // Ferme le clavier pour que le message soit bien visible.
    FocusScope.of(context).unfocus();
    // Message honnête : l'API n'existe pas encore, rien ne part.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text("Connexion bientôt disponible : rien n'a été envoyé."),
        ),
      );
  }

  /// Remplace la Connexion par l'Inscription (pushReplacement) : l'écran
  /// en dessous reste Bienvenue, et le bouton retour y ramène directement.
  void _openRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
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
              const LabeledTextField(
                fieldKey: LoginScreen.emailFieldKey,
                label: 'Adresse e-mail',
                hintText: 'nom@exemple.com',
                prefixIcon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: [AutofillHints.email],
                autocorrect: false,
                enableSuggestions: false,
                validator: AuthValidators.email,
              ),
              const SizedBox(height: AppSpacing.md),
              PasswordField(
                fieldKey: LoginScreen.passwordFieldKey,
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
              FilledButton(
                onPressed: _submit,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Se connecter'),
                    SizedBox(width: AppSpacing.sm),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
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
