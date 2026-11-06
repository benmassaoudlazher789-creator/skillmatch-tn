---
description: Construire un écran Flutter de SkillMatch TN à partir de la maquette Stitch (argument : numéro de l'écran)
---

Prochain écran : écran numéro $ARGUMENTS.

Lis d'abord CLAUDE.md, puis le dossier de design dont le nom commence par "$ARGUMENTS._" dans
design/stitch_skillmatch_tn_job_app/ (code.html et screen.png). Ne modifie rien avant que je
valide ton plan.

Écris d'abord un plan court, sans code :
- fichiers à créer ou modifier ;
- widgets partagés réutilisés (SkillChip, champs, boutons, thème) ;
- différences entre la maquette et ta proposition ;
- les questions dont tu as besoin pour avancer.

Règles (en plus de CLAUDE.md) :
- Données fictives marquées « exemple », aucun appel réseau, aucune donnée personnelle réelle.
- Mots interdits : vérifiée, certifiée, prouvée, passeport, défi, chiffré, robot.
- Aucune Row qui puisse déborder (Expanded, Flexible ou Wrap).
- Tests pour chaque comportement, y compris la navigation depuis l'écran précédent.
- Ne lance aucune commande et ne fais aucun commit : je lance moi-même dart format,
  flutter analyze et flutter test.