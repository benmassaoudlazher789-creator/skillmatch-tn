/// Adresse de l'API, choisie au moment du lancement :
///   flutter run --dart-define=API_URL=http://10.0.2.2:5080
///
/// Pourquoi --dart-define ? L'adresse change selon l'endroit où tourne
/// l'application (Chrome sur le PC, émulateur Android, plus tard un vrai
/// serveur) sans modifier le code. Sans option, on vise l'API lancée en
/// local par « dotnet run » (port 5080, voir launchSettings.json).
///
/// Ce n'est pas un secret : une adresse d'API n'a rien de confidentiel.
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:5080',
);
