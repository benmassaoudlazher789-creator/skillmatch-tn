# SkillMatch TN

Application mobile qui lit le CV d'un candidat, détecte ses compétences et
affiche des offres d'emploi, de stage et de PFE avec un pourcentage de
correspondance, les outils acquis et manquants (en rouge), puis des formations
pour apprendre les outils manquants.

## Stack
- Mobile : Flutter (dossier mobile/)
- API : ASP.NET Core sur .NET 10, C# (dossier backend/, à créer)
- Base : PostgreSQL 18, localhost port 3000, base skillmatch
- Interface en français. Un seul type d'utilisateur : le candidat.

## Design
Maquettes dans design/ : un dossier par écran avec code.html et screen.png.
Le style est dans le dossier skillmatch_tn/DESIGN.md.
Couleurs : bleu nuit #10243A, crème #F7F5EF, vert #0F7F6B, ambre #E8A33D.

## Règles
- Ne pas copier comme réelles les données d'exemple des maquettes (noms,
  entreprises, salaires, chiffres de recrutement, mentions d'hébergement).
- Ne jamais afficher les mots "vérifié", "passeport", "défi".
- Le score est une aide, pas une garantie.
- Ne jamais écrire de mot de passe ou de secret dans un fichier du projet.
- Expliquer simplement chaque choix technique : c'est un projet étudiant.