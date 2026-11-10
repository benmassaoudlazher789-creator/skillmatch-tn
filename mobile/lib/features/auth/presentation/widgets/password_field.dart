import 'package:flutter/material.dart';

import 'labeled_text_field.dart';

/// Champ « Mot de passe » avec le bouton œil pour afficher ou masquer.
///
/// Pourquoi un widget à part ? Inscription et Connexion ont le même champ.
/// C'est un StatefulWidget : il retient lui-même si le mot de passe est
/// visible, donc les écrans n'ont rien à gérer.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    this.fieldKey,
    this.helperText,
    required this.autofillHints,
    this.validator,
    this.onFieldSubmitted,
    this.controller,
  });

  /// Clé posée sur le champ lui-même (pratique pour les tests).
  final Key? fieldKey;

  /// Aide sous le champ (ex. « 8 caractères minimum » à l'Inscription).
  final String? helperText;

  /// newPassword à l'Inscription (le téléphone peut proposer un mot de
  /// passe), password à la Connexion (il peut remplir celui enregistré).
  final Iterable<String> autofillHints;

  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  /// Permet à l'écran de lire le mot de passe saisi pour l'envoyer à l'API.
  final TextEditingController? controller;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  /// Mot de passe masqué par défaut.
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return LabeledTextField(
      fieldKey: widget.fieldKey,
      controller: widget.controller,
      label: 'Mot de passe',
      helperText: widget.helperText,
      prefixIcon: Icons.lock_outline_rounded,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      autofillHints: widget.autofillHints,
      autocorrect: false,
      enableSuggestions: false,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      suffixIcon: IconButton(
        tooltip: _obscure
            ? 'Afficher le mot de passe'
            : 'Masquer le mot de passe',
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}
