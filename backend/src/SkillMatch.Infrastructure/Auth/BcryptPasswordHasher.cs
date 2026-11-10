using SkillMatch.Core.Users;

namespace SkillMatch.Infrastructure.Auth;

/// <summary>
/// Hachage BCrypt via le paquet BCrypt.Net-Next.
/// Pourquoi BCrypt : il est volontairement lent et ajoute un sel aléatoire à
/// chaque hash, ce qui rend très coûteuse une attaque qui essaie des millions
/// de mots de passe sur une copie de la base.
/// </summary>
public sealed class BcryptPasswordHasher : IPasswordHasher
{
    /// <summary>
    /// Facteur 12 : environ 250 ms par hash sur un PC récent. Assez lent pour
    /// freiner une attaque, assez rapide pour que l'utilisateur ne le remarque pas.
    /// Chaque +1 double le temps de calcul.
    /// </summary>
    public const int DefaultWorkFactor = 12;

    // Bornes acceptées par l'algorithme BCrypt lui-même.
    public const int MinWorkFactor = 4;
    public const int MaxWorkFactor = 31;

    private readonly int _workFactor;

    // Hash factice calculé une seule fois, au premier besoin, avec le même
    // facteur que les vrais hash : son contrôle prend donc le même temps.
    private readonly Lazy<string> _dummyHash;

    public BcryptPasswordHasher(int workFactor)
    {
        ArgumentOutOfRangeException.ThrowIfLessThan(workFactor, MinWorkFactor);
        ArgumentOutOfRangeException.ThrowIfGreaterThan(workFactor, MaxWorkFactor);

        _workFactor = workFactor;
        _dummyHash = new Lazy<string>(
            () => BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString("N"), _workFactor));
    }

    public string Hash(string password)
    {
        ArgumentException.ThrowIfNullOrEmpty(password);

        // Garde-fou en plus de la validation de l'API : BCrypt couperait le mot
        // de passe à 72 octets sans rien dire, on préfère une erreur claire.
        if (PasswordRules.ExceedsMaxBytes(password))
        {
            throw new ArgumentException(
                $"Le mot de passe dépasse {PasswordRules.MaxUtf8Bytes} octets.", nameof(password));
        }

        return BCrypt.Net.BCrypt.HashPassword(password, _workFactor);
    }

    public bool Verify(string password, string passwordHash)
    {
        ArgumentNullException.ThrowIfNull(password);
        ArgumentException.ThrowIfNullOrEmpty(passwordHash);

        // Sans ce test, « mot de passe de 72 octets + n'importe quoi » serait
        // accepté, car BCrypt ignorerait la fin. Aucun compte ne peut avoir un
        // mot de passe plus long (l'inscription le refuse), donc c'est forcément faux.
        if (PasswordRules.ExceedsMaxBytes(password))
        {
            return false;
        }

        return BCrypt.Net.BCrypt.Verify(password, passwordHash);
    }

    public void VerifyAgainstDummyHash(string password)
    {
        ArgumentNullException.ThrowIfNull(password);

        // Le résultat est ignoré : seul compte le temps passé, identique à un vrai contrôle.
        _ = BCrypt.Net.BCrypt.Verify(password, _dummyHash.Value);
    }
}
