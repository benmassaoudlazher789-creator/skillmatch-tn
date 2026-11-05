import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'auth_validators.dart';
import 'widgets/labeled_text_field.dart';
import 'widgets/terms_checkbox_field.dart';

/// Écran 2 : Inscription.
///
/// Le candidat saisit son nom, son e-mail et un mot de passe. L'API n'existe
/// pas encore : on vérifie seulement le formulaire sur le téléphone, et RIEN
/// n'est envoyé ni enregistré.
///
/// StatefulWidget, car l'écran garde un état qui change : mot de passe
/// visible ou masqué, et moment où les erreurs commencent à s'afficher.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.onSignIn});

  /// Action du lien « Se connecter ». L'écran Connexion n'existe pas encore :
  /// si rien n'est fourni, on affiche un message temporaire, comme sur
  /// l'écran Bienvenue.
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

  /// Mot de passe masqué par défaut.
  bool _obscurePassword = true;

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
    _showMessage("Inscription bientôt disponible : rien n'a été envoyé.");
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      // Couleurs, titre et barre d'état viennent de appBarTheme (app_theme.dart).
      appBar: AppBar(
        // Bouton retour personnalisé : IconButton fait au moins 48 × 48 px
        // (taille tactile recommandée) et son infobulle est en français.
        // Le BackButton par défaut afficherait « Back ».
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Retour',
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Inscription'),
      ),
      body: SafeArea(
        top: false, // l'AppBar s'occupe déjà du haut de l'écran
        child: SingleChildScrollView(
          // Faire défiler ferme le clavier : pratique sur un petit écran.
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenMargin,
                  AppSpacing.lg,
                  AppSpacing.screenMargin,
                  AppSpacing.xl,
                ),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autovalidateMode,
                  // AutofillGroup : le téléphone peut proposer le nom et
                  // l'e-mail qu'il connaît, et enregistrer le mot de passe.
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(text),
                        const SizedBox(height: AppSpacing.lg),
                        LabeledTextField(
                          fieldKey: RegisterScreen.nameFieldKey,
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
                        LabeledTextField(
                          fieldKey: RegisterScreen.passwordFieldKey,
                          label: 'Mot de passe',
                          helperText: '${AuthValidators.minPasswordLength} '
                              'caractères minimum',
                          prefixIcon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          // newPassword : le gestionnaire de mots de passe du
                          // téléphone peut en proposer un et l'enregistrer.
                          autofillHints: const [AutofillHints.newPassword],
                          autocorrect: false,
                          enableSuggestions: false,
                          validator: AuthValidators.password,
                          // « Terminé » sur le clavier = appui sur le bouton.
                          onFieldSubmitted: (_) => _submit(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Afficher le mot de passe'
                                : 'Masquer le mot de passe',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
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
                        _buildSignInLink(text),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Titre et sous-titre de l'écran.
  Widget _buildHeader(TextTheme text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header: true : le lecteur d'écran annonce ce texte comme un titre.
        Semantics(
          header: true,
          child: Text('Créez votre compte', style: text.displaySmall),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Quelques informations suffisent pour commencer.',
          style: text.bodyMedium?.copyWith(color: AppColors.carbon),
        ),
      ],
    );
  }

  /// Lien « Déjà inscrit ? Se connecter ». Wrap passe à la ligne si l'écran
  /// est très étroit ou si le texte est agrandi dans les réglages.
  Widget _buildSignInLink(TextTheme text) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Déjà inscrit ?',
          style: text.bodyMedium?.copyWith(color: AppColors.carbon),
        ),
        TextButton(
          onPressed: widget.onSignIn ??
              () => _showMessage('Écran « Connexion » à venir.'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.emerald,
            // 48 px de zone tactile (le thème met 40 pour les boutons
            // utilitaires).
            minimumSize: const Size(
              kMinInteractiveDimension,
              kMinInteractiveDimension,
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          ),
          child: const Text('Se connecter'),
        ),
      ],
    );
  }
}
