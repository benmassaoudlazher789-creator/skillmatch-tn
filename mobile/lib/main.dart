import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/welcome_screen.dart';
import 'features/cv/presentation/cv_upload_screen.dart';

/// ACCÈS TEMPORAIRE à l'écran Ajout du CV, en attendant que Connexion et
/// Inscription y mènent :
///   flutter run --dart-define=START_SCREEN=cv
/// Sans cette option, l'application s'ouvre normalement sur Bienvenue.
/// À retirer (cette constante et le test dans « home ») plus tard.
const _startScreen = String.fromEnvironment('START_SCREEN');

void main() {
  runApp(const SkillMatchApp());
}

/// Racine de l'application : applique le thème partagé et ouvre
/// l'écran Bienvenue.
class SkillMatchApp extends StatelessWidget {
  const SkillMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillMatch TN',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: _startScreen == 'cv'
          ? const CvUploadScreen()
          : const WelcomeScreen(),
    );
  }
}
