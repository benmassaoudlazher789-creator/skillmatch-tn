using System.Net.Mail;
using SkillMatch.Core.Users;

namespace SkillMatch.Api.Auth;

/// <summary>
/// Contrôle des champs reçus. Fonctions pures (sans serveur ni base) : elles se
/// testent directement. Les messages citent le champ, jamais la valeur saisie,
/// pour qu'un mot de passe ne revienne jamais dans une réponse.
/// </summary>
public static class AuthValidation
{
    public static Dictionary<string, string[]> ValidateRegister(RegisterRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        var errors = new Dictionary<string, string[]>();

        var fullName = request.FullName?.Trim();
        if (string.IsNullOrEmpty(fullName))
        {
            errors["fullName"] = ["Le nom complet est obligatoire."];
        }
        else if (fullName.Length > User.MaxFullNameLength)
        {
            errors["fullName"] = [$"Le nom complet ne doit pas dépasser {User.MaxFullNameLength} caractères."];
        }

        var email = request.Email?.Trim();
        if (string.IsNullOrEmpty(email))
        {
            errors["email"] = ["L'adresse e-mail est obligatoire."];
        }
        else if (email.Length > User.MaxEmailLength || !IsEmailFormat(email))
        {
            errors["email"] = ["L'adresse e-mail n'est pas valide."];
        }

        var password = request.Password;
        if (string.IsNullOrEmpty(password))
        {
            errors["password"] = ["Le mot de passe est obligatoire."];
        }
        else if (password.Length < PasswordRules.MinLength)
        {
            errors["password"] = [$"Le mot de passe doit contenir au moins {PasswordRules.MinLength} caractères."];
        }
        else if (PasswordRules.ExceedsMaxBytes(password))
        {
            errors["password"] =
            [
                $"Le mot de passe est trop long ({PasswordRules.MaxUtf8Bytes} octets au plus ; " +
                "une lettre accentuée compte pour 2).",
            ];
        }

        return errors;
    }

    /// <summary>
    /// À la connexion, on exige seulement des champs remplis : rappeler les règles
    /// de format ici n'aiderait qu'un attaquant. Un mauvais format donne
    /// simplement le 401 générique.
    /// </summary>
    public static Dictionary<string, string[]> ValidateLogin(LoginRequest request)
    {
        ArgumentNullException.ThrowIfNull(request);

        var errors = new Dictionary<string, string[]>();

        if (string.IsNullOrWhiteSpace(request.Email))
        {
            errors["email"] = ["L'adresse e-mail est obligatoire."];
        }

        if (string.IsNullOrEmpty(request.Password))
        {
            errors["password"] = ["Le mot de passe est obligatoire."];
        }

        return errors;
    }

    // MailAddress connaît la syntaxe d'une adresse. La comparaison finale refuse
    // les formes « Nom <adresse> », que MailAddress accepte mais qui ne sont pas
    // une simple adresse. Seul l'envoi d'un message montrerait que l'adresse existe.
    private static bool IsEmailFormat(string email) =>
        MailAddress.TryCreate(email, out var address)
        && string.Equals(address.Address, email, StringComparison.OrdinalIgnoreCase);
}
