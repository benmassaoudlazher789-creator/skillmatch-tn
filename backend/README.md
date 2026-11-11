# SkillMatch TN : API

API ASP.NET Core (.NET 10) de l'application mobile SkillMatch TN.

## Structure

| Projet | Rôle |
|---|---|
| `src/SkillMatch.Core` | Domaine : comptes, type d'un CV, détection des compétences (fonctions pures). Aucune dépendance. |
| `src/SkillMatch.Infrastructure` | Accès à PostgreSQL (Entity Framework Core, Npgsql) et lecture des CV (PdfPig, Open XML SDK). |
| `src/SkillMatch.Api` | Endpoints HTTP : `GET /health`, `POST /auth/register`, `POST /auth/login`, `POST /cv`. |
| `tests/SkillMatch.Tests` | Tests xUnit v3, avec l'API démarrée en mémoire et une base SQLite en mémoire. |

Les versions des paquets se trouvent toutes dans `Directory.Packages.props`.

## Ports

- **PostgreSQL :** `localhost:3000`, base `skillmatch`. Ce n'est pas le port par défaut (5432) : il faut donc écrire `Port=3000` dans la chaîne de connexion.
- **API :** `http://localhost:5080`. Ne jamais utiliser 3000, qui est déjà pris par PostgreSQL.

## Chaîne de connexion (dotnet user-secrets)

Aucun mot de passe ni aucune chaîne de connexion n'est écrit dans le dépôt. La valeur est rangée sur votre machine, dans `%APPDATA%\Microsoft\UserSecrets\<UserSecretsId>\secrets.json`, hors du dépôt. Ce fichier n'est pas protégé : c'est un simple fichier texte, pas un coffre-fort.

Le `UserSecretsId` est déjà dans `SkillMatch.Api.csproj` : la commande `dotnet user-secrets init` n'est donc pas nécessaire.

Depuis `backend/`, remplacez les valeurs entre chevrons :

```
dotnet user-secrets set "ConnectionStrings:SkillMatch" "Host=localhost;Port=3000;Database=skillmatch;Username=<utilisateur>;Password=<mot_de_passe>" --project src/SkillMatch.Api
dotnet user-secrets list --project src/SkillMatch.Api
```

- **Quand elle est chargée :** les user-secrets ne sont lus qu'en environnement `Development`, que `launchSettings.json` règle pour `dotnet run`. En production, on passera par la variable d'environnement `ConnectionStrings__SkillMatch`.
- **Historique PowerShell :** la commande `set` y laisse le mot de passe. Vous pouvez l'effacer ensuite, ou utiliser un rôle PostgreSQL dédié avec peu de droits.
- **Si la chaîne manque :** l'API démarre quand même et `/health` répond. Seul un endpoint qui utilise la base échoue, avec un message qui renvoie ici.

## Clé de signature des jetons (dotnet user-secrets)

L'API signe ses jetons JWT (HMAC-SHA256) avec la clé `Jwt:SigningKey`. Cette clé n'est écrite dans aucun fichier du dépôt : comme la chaîne de connexion, elle se range dans les user-secrets.

1. Générez une clé aléatoire dans PowerShell (64 octets, affichés en Base64) :

   ```
   $b = New-Object byte[] 64; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b); [Convert]::ToBase64String($b)
   ```

2. Depuis `backend/`, enregistrez-la en remplaçant la valeur entre chevrons :

   ```
   dotnet user-secrets set "Jwt:SigningKey" "<COLLER_ICI_LA_CLE_GENEREE>" --project src/SkillMatch.Api
   ```

- **Si la clé manque ou fait moins de 32 octets :** l'API refuse de démarrer et affiche un message qui renvoie ici. Une clé courte pourrait être retrouvée par essais successifs.
- **En production :** variable d'environnement `Jwt__SigningKey`.
- **Le reste du réglage est dans `appsettings.json`** (ce ne sont pas des secrets) : émetteur `skillmatch-api`, destinataire `skillmatch-mobile`, durée de 30 minutes.

## Comptes : inscription et connexion

| Route | Corps | Réponses |
|---|---|---|
| `POST /auth/register` | `{ "fullName", "email", "password" }` | `201` `{ id, fullName, email }` (sans jeton) · `400` champs invalides · `409` adresse déjà utilisée · `429` |
| `POST /auth/login` | `{ "email", "password" }` | `200` `{ accessToken, tokenType: "Bearer", expiresIn }` · `400` champs vides · `401` message unique · `429` |

- **Mots de passe :** hachés avec BCrypt (paquet `BCrypt.Net-Next`), facteur 12 (environ 250 ms par hash), réglable par `PasswordHashing:WorkFactor`. Les tests utilisent le facteur 4 pour aller vite.
- **Longueur :** 8 caractères au moins et 72 octets UTF-8 au plus. BCrypt ignore tout ce qui dépasse 72 octets, donc l'API refuse plutôt que de couper en silence. Une lettre accentuée compte pour 2 octets.
- **E-mail :** sans espaces autour et en minuscules avant l'enregistrement et avant la recherche. Un doublon est refusé (`409`), aussi par l'index unique en cas d'inscriptions simultanées (erreur PostgreSQL `23505`).
- **Connexion :** même réponse `401` pour un e-mail inconnu et pour un mauvais mot de passe, avec le même temps de calcul.
- **Jeton :** 30 minutes, sans jeton de renouvellement. Il ne contient que l'Id du compte (`sub`) et un identifiant de jeton (`jti`), car n'importe qui peut lire le contenu d'un JWT.
- **Limite d'essais :** 5 requêtes par minute et par adresse IP sur `/auth/*` (réglage `RateLimiting:Auth:PermitLimit`). Au-delà, l'API répond `429`.
- **Logs :** jamais de mot de passe ni de corps de requête. Les logs d'audit contiennent l'événement, l'Id du compte et l'adresse IP.

## Analyse du CV : `POST /cv`

| Requête | Réponses |
|---|---|
| En-tête `Authorization: Bearer <jeton>`, formulaire `multipart/form-data` avec un seul champ `file` (PDF ou DOCX, 5 Mo au plus) | `200` `{ "skills": ["Dart", "Flutter"] }` (liste vide possible) · `400` formulaire invalide, champ absent, plusieurs fichiers, fichier vide · `401` jeton absent ou expiré · `413` trop volumineux · `415` ni PDF ni DOCX · `422` fichier protégé, illisible ou sans texte · `429` |

Les erreurs ont la forme `{ "code": "no_text", "title": "<message en français>" }`. Le `code` est stable : l'application s'en sert pour choisir son message.

- **Confidentialité (choix validé) :** le CV est lu en mémoire puis oublié. Rien n'est écrit en base ni sur le disque. ASP.NET range d'habitude sur le disque les fichiers reçus de plus de 64 Ko ; ce seuil est relevé pour cette route, donc le fichier reste en mémoire.
- **Journaux :** seulement le code de réponse et la durée. Jamais de nom de fichier, de texte ni de compétences. Le nom du fichier envoyé n'est même pas lu. Un test vérifie que des marqueurs fictifs placés dans le CV et dans son nom n'apparaissent dans aucun message.
- **Type du fichier :** reconnu par sa signature (ses premiers octets), jamais par son extension ni par le type annoncé. Un PDF commence par `%PDF-`, un DOCX par `PK` (c'est une archive ZIP). Pour un DOCX, l'archive doit aussi contenir `[Content_Types].xml` et `word/document.xml`, et ne pas contenir de macros. Les anciens fichiers `.doc` ne sont pas acceptés.
- **Protections :**
  - 10 pages lues au plus dans un PDF, 100 000 caractères de texte au plus ;
  - pour un DOCX, 1 000 fichiers et 20 Mo une fois décompressé au plus (contre les « bombes ZIP ») ;
  - 10 analyses par minute et par compte (réglage `RateLimiting:Cv:PermitLimit`).
- **Détection :** un dictionnaire d'environ 80 outils, chacun avec ses variantes (`Core/Skills/SkillDictionary.cs`). Majuscules et accents ne comptent pas, et seuls les mots entiers sont reconnus : « Java » n'est pas trouvé dans « JavaScript ». Les mots ambigus ne sont reconnus que sous une forme précise (« golang » pour Go, « vue.js » pour Vue.js). Un outil absent du dictionnaire n'est pas détecté : le candidat l'ajoute lui-même dans l'application.
- **Limites connues :** pas de lecture des CV scannés (images) : la reconnaissance de texte (OCR) n'est pas prévue. Un PDF protégé par un mot de passe est refusé.
- **HTTPS :** en local, l'API tourne en `http` et le CV passe en clair sur la machine. C'est acceptable pour développer, mais un vrai déploiement devra passer en HTTPS.
- **Tests :** les CV de test sont fabriqués pendant les tests, avec un texte fictif. Aucun vrai CV n'est rangé dans le dépôt.

## Offres : `GET /offers`

| Requête | Réponses |
|---|---|
| En-tête `Authorization: Bearer <jeton>`, `GET /offers?skill=Flutter&skill=SQL&limit=20` | `200` `{ "offers": [ … ] }` · `400` trop de compétences, compétence trop longue, `limit` invalide · `401` jeton absent ou expiré |

Chaque offre renvoyée contient `id`, `title`, `company`, `type` (`stage`, `pfe` ou `emploi`), `city`, `url`, `source`, `isSample`, `publishedAt`, `score`, `requiredAcquired`, `requiredMissing`, `preferredAcquired`, `preferredMissing` et `explanation`.

- **Compétences (choix validé) :** envoyées par l'application à chaque appel, 50 au plus, 40 caractères chacune. L'API ne les enregistre pas et ne les écrit dans aucun journal. Le journal d'ASP.NET qui note l'adresse des requêtes reste réglé sur `Warning` (`appsettings.json`), et un test vérifie qu'aucun message ne contient les compétences envoyées.
- **Score :** 70 % pour les compétences requises, 30 % pour les souhaitées, arrondi vers le bas (`Core/Jobs/MatchScorer.cs`), comme dans l'application. Si l'offre n'a qu'une des deux listes, celle-ci compte pour 100 %. Le score est une aide, pas une garantie.
- **Comparaison souple (choix validé) :** majuscules et accents ne comptent pas, et les variantes du dictionnaire se valent : « JS » correspond à « JavaScript », « k8s » à « Kubernetes » (`Core/Skills/SkillKey.cs`).
- **Ordre :** meilleur score d'abord, puis l'offre la plus récente, puis l'Id. `limit` vaut 20 par défaut, de 1 à 50.
- **Sources :** toute source d'offres implémente `IJobSource` (`Core/Jobs/IJobSource.cs`). `JobImporter` copie ses offres en base : une offre déjà connue (même `source` et même `external_id`) est mise à jour, et une offre invalide (lien autre que `http`/`https`, compétence en double…) est écartée sans bloquer les autres. Aucune source réelle n'est branchée pour l'instant.
- **Offres d'exemple :** 12 offres fictives (`Infrastructure/Jobs/SampleJobSource.cs`), source `exemple`, `isSample: true`, entreprises « Société Exemple … » et liens sur `example.com` (domaine réservé aux exemples). Elles sont importées au démarrage **en développement seulement**, avec le profil `http` de `launchSettings.json` (`Jobs__ImportSampleOnStartup=true`). Relancer l'API ne crée pas de doublon. Hors développement, le service d'import n'est même pas enregistré.
- **Limite connue :** toutes les offres sont notées en mémoire, ce qui suffit pour quelques centaines. Avec une vraie source plus volumineuse, il faudra filtrer d'abord en SQL. Une offre retirée par sa source reste aussi en base pour l'instant.

## Commandes

```
dotnet build
dotnet test
dotnet run --project src/SkillMatch.Api
```

Ensuite, ouvrez `http://localhost:5080/health` : la réponse attendue est `{"status":"ok"}`.

`dotnet test` n'a pas besoin de PostgreSQL : les tests tournent en environnement `Testing`, sans user-secrets. Ils utilisent une base SQLite en mémoire et une clé de jeton tirée au hasard à chaque exécution.

## Base de données et migrations

Trois tables : `users`, `jobs` et `job_skills`.

| Colonne | Contenu |
|---|---|
| `id` | Guid v7, la clé primaire `pk_users` |
| `full_name` | 100 caractères au plus |
| `email` | En minuscules, index unique `ix_users_email` |
| `password_hash` | Le hash, jamais le mot de passe |
| `created_at` | `timestamp with time zone`, en UTC |

Table `jobs` (migration `AddJobs`) :

| Colonne | Contenu |
|---|---|
| `id` | Guid v7, la clé primaire `pk_jobs` |
| `title`, `company`, `city` | 200, 200 et 100 caractères au plus |
| `type` | `stage`, `pfe` ou `emploi` (texte) |
| `url` | Lien `http` ou `https`, facultatif |
| `source`, `external_id` | La source et l'identifiant chez elle, index unique `ix_jobs_source_external_id` |
| `is_sample` | Vrai pour une offre d'exemple |
| `published_at`, `imported_at` | `timestamp with time zone`, en UTC |

Table `job_skills` : `job_id` et `name` (clé primaire `pk_job_skills`, donc une compétence par offre au plus une fois), `importance` (`required` ou `preferred`). Supprimée avec son offre (cascade).

### Ajouter la migration des offres

```
dotnet build
dotnet ef migrations add AddJobs --project src/SkillMatch.Infrastructure --startup-project src/SkillMatch.Api --output-dir Persistence/Migrations
dotnet ef migrations script InitialCreate AddJobs --project src/SkillMatch.Infrastructure --startup-project src/SkillMatch.Api
dotnet ef database update --project src/SkillMatch.Infrastructure --startup-project src/SkillMatch.Api
```

Ensuite, `dotnet run --project src/SkillMatch.Api` importe les offres d'exemple au démarrage. Le journal affiche « Offres d'exemple importées : … ».

### Avant la première migration

- **La chaîne de connexion :** elle doit déjà être dans les user-secrets (voir plus haut). `dotnet ef` lance `Program.cs` en environnement `Development` et en a besoin, même pour créer une migration sans se connecter.
- **La base :** `skillmatch` doit exister. Sinon, il faut que votre rôle ait le droit de créer des bases, ou bien : `CREATE DATABASE skillmatch OWNER <role>;`.
- **Le droit de créer des tables :** depuis PostgreSQL 15, un rôle ordinaire ne peut plus créer de tables dans le schéma `public`. Votre rôle doit donc être propriétaire de la base, ou bien : `GRANT CREATE ON SCHEMA public TO <role>;`.

### Commandes (depuis `backend/`)

```
dotnet new tool-manifest
dotnet tool install dotnet-ef --version 10.0.0
dotnet build
dotnet ef migrations add InitialCreate --project src/SkillMatch.Infrastructure --startup-project src/SkillMatch.Api --output-dir Persistence/Migrations
dotnet ef migrations script --project src/SkillMatch.Infrastructure --startup-project src/SkillMatch.Api
dotnet ef database update --project src/SkillMatch.Infrastructure --startup-project src/SkillMatch.Api
```

- **L'outil local :** `backend/dotnet-tools.json` fixe la version de `dotnet-ef` et ne contient aucun secret. Sur une autre machine, `dotnet tool restore` suffit.
- **`migrations script` :** il affiche le SQL sans rien exécuter. Relisez-le avant `database update`.
- **Pour défaire une migration :** `dotnet ef migrations remove` fonctionne tant qu'elle n'est pas appliquée. Une migration déjà appliquée ne se modifie pas, on en ajoute une nouvelle.
- **Si l'environnement n'est pas `Development` :** si `ASPNETCORE_ENVIRONMENT` est réglé autrement dans votre session, ajoutez `-- --environment Development` à la fin des commandes `dotnet ef`.
- **La chaîne de connexion :** ne l'écrivez jamais dans une commande enregistrée (script, tâche VS Code, README).

## Plus tard

- **`/health/db` :** une sonde qui contrôle aussi la base, avec `AddDbContextCheck`.
- **Émulateur Android :** il joint l'API via `http://10.0.2.2:5080`, et non `localhost`.
- **CORS (développement seulement) :** l'application lancée dans Chrome (`http://localhost:<port>`) peut appeler l'API avec `GET`, `POST`, `Content-Type` et `Authorization` (voir `Api/Cors/DevCors.cs`).
