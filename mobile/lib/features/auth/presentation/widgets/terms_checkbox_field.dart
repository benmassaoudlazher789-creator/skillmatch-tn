import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../auth_validators.dart';

/// Case « J'accepte les conditions… », avec son message d'erreur en dessous.
///
/// Pourquoi FormField ? Une Checkbox seule ne sait pas se valider. Une fois
/// placée dans un FormField, elle fait partie du Form comme les champs texte :
/// validate() vérifie aussi la case et affiche l'erreur juste en dessous.
class TermsCheckboxField extends StatelessWidget {
  const TermsCheckboxField({super.key});

  /// Clé de la case (pratique pour les tests).
  static const checkboxKey = Key('register_terms');

  static const label = "J'accepte les conditions d'utilisation et la "
      'politique de confidentialité.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FormField<bool>(
      initialValue: false,
      validator: AuthValidators.termsAccepted,
      builder: (field) {
        final checked = field.value ?? false;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MergeSemantics : le lecteur d'écran annonce la case et son
            // texte comme un seul élément (« case non cochée, J'accepte… »).
            MergeSemantics(
              child: InkWell(
                // Toucher le texte coche aussi la case : la zone tactile est
                // plus grande et plus facile à viser.
                onTap: () => field.didChange(!checked),
                borderRadius: BorderRadius.circular(AppRadius.small),
                child: Row(
                  children: [
                    Checkbox(
                      key: checkboxKey,
                      value: checked,
                      // Bordure rouge quand la case est en erreur (voir
                      // checkboxTheme dans app_theme.dart).
                      isError: field.hasError,
                      onChanged: (value) => field.didChange(value ?? false),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.carbon),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                // Aligné sous le texte : 48 px de case + petit écart.
                padding: const EdgeInsets.only(
                  left: kMinInteractiveDimension + AppSpacing.xs,
                ),
                child: Text(
                  field.errorText!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ),
          ],
        );
      },
    );
  }
}
