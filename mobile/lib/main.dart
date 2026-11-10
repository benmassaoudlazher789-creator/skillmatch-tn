import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/welcome_screen.dart';

// L'ancien raccourci --dart-define=START_SCREEN=cv a été retiré : la
// Connexion et l'Inscription mènent maintenant à l'écran Ajout du CV.

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
      home: const WelcomeScreen(),
    );
  }
}
