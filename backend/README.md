# SkillMatch TN : API

API ASP.NET Core (.NET 10) de l'application mobile SkillMatch TN.

## Structure

| Projet | Rôle |
|---|---|
| `src/SkillMatch.Core` | Domaine (compétences, offres, score). Aucune dépendance. |
| `src/SkillMatch.Infrastructure` | Accès à PostgreSQL via Entity Framework Core et Npgsql. |
| `src/SkillMatch.Api` | Endpoints HTTP (pour l'instant `GET /health`). |
| `tests/SkillMatch.Tests` | Tests xUnit v3, avec l'API démarrée en mémoire. |

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

## Commandes

```
dotnet build
dotnet test
dotnet run --project src/SkillMatch.Api
```

Ensuite, ouvrez `http://localhost:5080/health` : la réponse attendue est `{"status":"ok"}`.

`dotnet test` n'a pas besoin de PostgreSQL : les tests tournent en environnement `Testing`, sans user-secrets.

## Base de données et migrations

Pour l'instant, une seule table : `users`.

| Colonne | Contenu |
|---|---|
| `id` | Guid v7, la clé primaire `pk_users` |
| `full_name` | 100 caractères au plus |
| `email` | En minuscules, index unique `ix_users_email` |
| `password_hash` | Le hash, jamais le mot de passe |
| `created_at` | `timestamp with time zone`, en UTC |

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

- **L'outil local :** `.config/dotnet-tools.json` fixe la version de `dotnet-ef` et ne contient aucun secret. Sur une autre machine, `dotnet tool restore` suffit.
- **`migrations script` :** il affiche le SQL sans rien exécuter. Relisez-le avant `database update`.
- **Pour défaire une migration :** `dotnet ef migrations remove` fonctionne tant qu'elle n'est pas appliquée. Une migration déjà appliquée ne se modifie pas, on en ajoute une nouvelle.
- **Si l'environnement n'est pas `Development` :** si `ASPNETCORE_ENVIRONMENT` est réglé autrement dans votre session, ajoutez `-- --environment Development` à la fin des commandes `dotnet ef`.
- **La chaîne de connexion :** ne l'écrivez jamais dans une commande enregistrée (script, tâche VS Code, README).

## Plus tard

- **`/health/db` :** une sonde qui contrôle aussi la base, avec `AddDbContextCheck`.
- **Inscription :** hachage avec `PasswordHasher<T>`. L'erreur PostgreSQL `23505` (e-mail déjà pris) sera transformée en réponse 409.
- **Émulateur Android :** il joint l'API via `http://10.0.2.2:5080`, et non `localhost`.
