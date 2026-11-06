import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// Champ de saisie avec son libellé affiché au-dessus. DESIGN.md demande
/// un libellé en label-md, bleu nuit, placé au-dessus du champ.
///
/// Pourquoi un widget à part ? Les trois champs de l'Inscription (et bientôt
/// ceux de la Connexion) ont la même structure : on l'écrit une seule fois.
/// L'apparence du champ (fond blanc, bordure, vert au focus, rouge en
/// erreur, texte d'aide) vient de inputDecorationTheme dans app_theme.dart.
class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    required this.label,
    this.fieldKey,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.validator,
    this.onFieldSubmitted,
    this.controller,
    this.maxLength,
  });

  /// Libellé toujours visible. Un texte d'exemple, lui, disparaît dès qu'on
  /// tape, d'où l'intérêt d'un vrai libellé.
  final String label;

  /// Clé posée sur le champ lui-même (pratique pour les tests).
  final Key? fieldKey;

  /// Texte d'exemple, en gris, dans le champ vide.
  final String? hintText;

  /// Aide affichée sous le champ. Le message d'erreur la remplace si besoin.
  final String? helperText;

  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool autocorrect;
  final bool enableSuggestions;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;

  /// Optionnel : permet à l'écran de lire ou de vider le champ (par exemple
  /// après l'ajout d'une compétence).
  final TextEditingController? controller;

  /// Optionnel : nombre maximal de caractères. Flutter bloque la saisie
  /// au-delà et affiche un compteur (« 12/40 ») sous le champ.
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // labelMedium est déjà en bleu nuit grâce au thème.
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: fieldKey,
          controller: controller,
          maxLength: maxLength,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          autofillHints: autofillHints,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
