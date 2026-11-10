using Microsoft.EntityFrameworkCore;
using Npgsql;
using SkillMatch.Core.Users;
using SkillMatch.Infrastructure.Persistence;

namespace SkillMatch.Infrastructure.Auth;

/// <summary>
/// Inscription et connexion d'un candidat. Les endpoints HTTP restent minces :
/// toute la logique est ici, et ne connaît ni JSON ni codes HTTP.
/// </summary>
public sealed class AuthService(SkillMatchDbContext db, IPasswordHasher passwordHasher)
{
    /// <summary>
    /// Crée le compte. Renvoie <c>null</c> si l'adresse est déjà utilisée.
    /// Les champs doivent avoir été validés avant (voir AuthValidation dans l'API).
    /// </summary>
    public async Task<User?> RegisterAsync(
        string fullName,
        string email,
        string password,
        CancellationToken cancellationToken)
    {
        var normalizedEmail = User.NormalizeEmail(email);

        // Recherche préalable : donne une réponse claire dans le cas courant et
        // évite de calculer un hash BCrypt (lent) pour rien.
        if (await db.Users.AnyAsync(u => u.Email == normalizedEmail, cancellationToken))
        {
            return null;
        }

        var user = User.Create(fullName, email, passwordHasher.Hash(password));
        db.Users.Add(user);

        try
        {
            await db.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException
        {
            SqlState: PostgresErrorCodes.UniqueViolation,
        })
        {
            // Deux inscriptions simultanées avec la même adresse passent toutes les
            // deux la recherche préalable ; l'index unique ix_users_email refuse
            // la seconde (erreur PostgreSQL 23505), qu'on traite comme un doublon.
            return null;
        }

        return user;
    }

    /// <summary>
    /// Renvoie le compte si l'e-mail et le mot de passe correspondent, sinon <c>null</c>.
    /// Le résultat est le même pour un e-mail inconnu et pour un mauvais mot de passe.
    /// </summary>
    public async Task<User?> LoginAsync(string email, string password, CancellationToken cancellationToken)
    {
        var normalizedEmail = User.NormalizeEmail(email);

        // AsNoTracking : simple lecture, EF Core n'a pas à suivre les modifications.
        var user = await db.Users
            .AsNoTracking()
            .SingleOrDefaultAsync(u => u.Email == normalizedEmail, cancellationToken);

        if (user is null)
        {
            // Même temps de calcul que pour un compte existant : la durée de la
            // réponse ne révèle pas si l'adresse a un compte.
            passwordHasher.VerifyAgainstDummyHash(password);
            return null;
        }

        return passwordHasher.Verify(password, user.PasswordHash) ? user : null;
    }
}
