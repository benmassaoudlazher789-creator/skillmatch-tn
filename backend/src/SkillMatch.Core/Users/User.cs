namespace SkillMatch.Core.Users;

/// <summary>
/// Compte d'un candidat (le seul type d'utilisateur de SkillMatch TN).
/// Les setters sont privés : on ne crée un utilisateur que par <see cref="Create"/>,
/// ce qui garantit qu'aucun objet invalide (e-mail non normalisé, nom vide…)
/// n'arrive jusqu'à la base.
/// </summary>
public sealed class User
{
    // Limites partagées avec la configuration EF Core : une seule valeur
    // pour la validation du domaine et la taille des colonnes.
    public const int MaxFullNameLength = 100;

    // 254 caractères : longueur maximale pratique d'une adresse e-mail.
    public const int MaxEmailLength = 254;

    // Large marge : un hash BCrypt fait 60 caractères. Garder 500 laisse la
    // place à un autre algorithme plus tard, sans nouvelle migration.
    public const int MaxPasswordHashLength = 500;

    public Guid Id { get; private set; }

    public string FullName { get; private set; } = string.Empty;

    /// <summary>Toujours en minuscules et sans espaces autour (voir <see cref="Create"/>).</summary>
    public string Email { get; private set; } = string.Empty;

    /// <summary>
    /// Hash du mot de passe, jamais le mot de passe lui-même.
    /// Il est calculé par <see cref="IPasswordHasher"/> (BCrypt, dans l'infrastructure).
    /// </summary>
    public string PasswordHash { get; private set; } = string.Empty;

    /// <summary>Date de création, en UTC (Npgsql refuse un décalage horaire non nul).</summary>
    public DateTimeOffset CreatedAt { get; private set; }

    // Constructeur vide réservé à EF Core, qui en a besoin pour relire une ligne.
    private User()
    {
    }

    public static User Create(string fullName, string email, string passwordHash)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(fullName);
        ArgumentException.ThrowIfNullOrWhiteSpace(email);
        ArgumentException.ThrowIfNullOrWhiteSpace(passwordHash);

        var normalizedName = fullName.Trim();
        // Normalisation faite ici, dans le domaine : « Ali@X.com » et « ali@x.com »
        // deviennent la même valeur, donc l'index unique simple suffit en base.
        var normalizedEmail = NormalizeEmail(email);

        if (normalizedName.Length > MaxFullNameLength)
        {
            throw new ArgumentException(
                $"Le nom complet dépasse {MaxFullNameLength} caractères.", nameof(fullName));
        }

        if (normalizedEmail.Length > MaxEmailLength)
        {
            throw new ArgumentException(
                $"L'adresse e-mail dépasse {MaxEmailLength} caractères.", nameof(email));
        }

        // Contrôle volontairement minimal : la seule façon sûre de valider
        // une adresse est d'y envoyer un message, ce qui viendra plus tard.
        if (!normalizedEmail.Contains('@'))
        {
            throw new ArgumentException("L'adresse e-mail doit contenir un « @ ».", nameof(email));
        }

        if (passwordHash.Length > MaxPasswordHashLength)
        {
            throw new ArgumentException(
                $"Le hash dépasse {MaxPasswordHashLength} caractères.", nameof(passwordHash));
        }

        return new User
        {
            // Guid version 7 : commence par l'heure, donc les nouvelles lignes
            // s'ajoutent en fin d'index (moins de fragmentation qu'un Guid aléatoire),
            // et l'Id ne permet pas de deviner celui des autres comptes.
            Id = Guid.CreateVersion7(),
            FullName = normalizedName,
            Email = normalizedEmail,
            PasswordHash = passwordHash,
            CreatedAt = DateTimeOffset.UtcNow,
        };
    }

    /// <summary>
    /// Forme unique d'une adresse : sans espaces autour et en minuscules.
    /// Publique pour que la connexion cherche l'adresse exactement sous la forme
    /// où l'inscription l'a enregistrée (une seule règle, à un seul endroit).
    /// </summary>
    public static string NormalizeEmail(string email)
    {
        ArgumentNullException.ThrowIfNull(email);
        return email.Trim().ToLowerInvariant();
    }
}
