import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'auth_validators.dart';
import 'login_screen.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_switch_link.dart';
import 'widgets/labeled_text_field.dart';
import 'widgets/password_field.dart';
import 'widgets/terms_checkbox_field.dart';

/// Écran 2 : Inscription.
///
/// Le candidat saisit son nom, son e-mail et un mot de passe. L'API n'existe
/// pas encore : on vérifie seulement le formulaire sur le téléphone, et RIEN
/// n'est envoyé ni enregistré.
///
/// StatefulWidget, car l'écran retient le moment où les erreurs commencent
/// à s'afficher.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.onSignIn});

  /// Action du lien « Se connecter ». Par défaut, il ouvre la Connexion à
  /// la place de l'Inscription (voir _openLogin).
  final VoidCallback? onSignIn;

  // Clés qui permettent aux tests de retrouver chaque champ.
  static const nameFieldKey = Key('register_name');
  static const emailFieldKey = Key('register_email');
  static const passwordFieldKey = Key('register_password');

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  /// Clé du formulaire : elle permet de valider tous les champs d'un coup.
  final _formKey = GlobalKey<FormState>();

  /// Au début, aucune erreur ne s'affiche : on ne signale rien avant que le
  /// candidat ait essayé. Après le premier appui sur « Créer mon compte »,
  /// les messages se mettent à jour à chaque modification.
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
          content: Text(
            "Inscription bientôt disponible : rien n'a été envoyé.",
          ),
        ),
      );
  }

  /// Remplace l'Inscription par la Connexion (pushReplacement) : l'écran
  /// en dessous reste Bienvenue, et le bouton retour y ramène directement.
  /// Avec un simple push, les écrans s'empileraient à chaque aller-retour.
  void _openLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
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
              const LabeledTextField(
                fieldKey: RegisterScreen.nameFieldKey,
                label: 'Nom complet',
                hintText: 'Prénom et nom',
                prefixIcon: Icons.badge_outlined,
                keyboardType: TextInputType.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: [AutofillHints.name],
                validator: AuthValidators.fullName,
              ),
              const SizedBox(height: AppSpacing.md),
              const LabeledTextField(
                fieldKey: RegisterScreen.emailFieldKey,
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
                fieldKey: RegisterScreen.passwordFieldKey,
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
              FilledButton(
                onPressed: _submit,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Créer mon compte'),
                    SizedBox(width: AppSpacing.sm),
                    Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ),
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
