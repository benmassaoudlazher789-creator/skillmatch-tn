/// Règles de validation des formulaires de compte (Inscription, puis
/// Connexion).
///
/// Ce sont des fonctions simples, sans widget : on peut les tester seules
/// et les réutiliser. Chacune renvoie null si la valeur est correcte, sinon
/// le message d'erreur en français. C'est le format attendu par le
/// paramètre `validator` de TextFormField.
abstract final class AuthValidators {
  /// Longueur minimale du mot de passe.
  static const int minPasswordLength = 8;

  /// Format d'e-mail volontairement simple : « texte@texte.extension »,
  /// sans espace, avec une extension d'au moins 2 lettres. Une règle
  /// parfaite est impossible ; la vraie vérification se fera plus tard
  /// côté serveur (par exemple en envoyant un e-mail de confirmation).
  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Veuillez saisir votre nom complet.';
    }
    return null;
  }

  static String? email(String? value) {
    // On ignore les espaces au début et à la fin (copier-coller fréquent).
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Veuillez saisir votre adresse e-mail.';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Adresse e-mail invalide (exemple : nom@exemple.com).';
    }
    return null;
  }

  static String? password(String? value) {
    // Pas de trim ici : un espace fait partie du mot de passe.
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir un mot de passe.';
    }
    if (value.length < minPasswordLength) {
      return 'Le mot de passe doit contenir au moins '
          '$minPasswordLength caractères.';
    }
    return null;
  }

  /// Connexion : on vérifie seulement que le mot de passe n'est pas vide.
  /// La règle des 8 caractères ne concerne que la création du compte.
  static String? passwordRequired(String? value) =>
      (value == null || value.isEmpty)
      ? 'Veuillez saisir votre mot de passe.'
      : null;

  static String? termsAccepted(bool? value) => value == true
      ? null
      : 'Vous devez accepter les conditions pour créer un compte.';
}
